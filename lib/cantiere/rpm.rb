# JBoss, Home of Professional Open Source
# Copyright 2009, Red Hat Middleware LLC, and individual contributors
# by the @authors tag. See the copyright.txt in the distribution for a
# full listing of individual contributors.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 2.1 of
# the License, or (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this software; if not, write to the Free
# Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA, or see the FSF site: http://www.fsf.org.

module Cantiere
  class RPM < Rake::TaskLib

    def self.provides
      @provides ||= {}
    end

    def self.provides_rpm_path
      @provides_rpm_path ||= {}
    end

    def initialize( config, spec_file, options = {}  )
      @config     = config
      @spec_file  = spec_file

      @log          = options[:log]         || LOG
      @exec_helper  = options[:exec_helper] || EXEC_HELPER

      @simple_name = File.basename( @spec_file, ".spec" )

      @rpm_release    = nil
      @rpm_version    = nil
      @rpm_is_noarch  = nil

      Dir.chdir( File.dirname( @spec_file ) ) do
        @rpm_release     = `rpm --specfile #{@simple_name}.spec -q --qf '%{Release}\\n' 2> /dev/null`.split("\n").first
        @rpm_version     = `rpm --specfile #{@simple_name}.spec -q --qf '%{Version}\\n' 2> /dev/null`.split("\n").first
        @rpm_is_noarch   = `rpm --specfile #{@simple_name}.spec -q --qf '%{arch}\\n' 2> /dev/null`.split("\n").first == "noarch"
      end

      @rpm_arch = @rpm_is_noarch ? "noarch" : @config.build_arch

      @rpm_file             = "#{@config.dir.top}/#{@config.os_path}/RPMS/#{@rpm_arch}/#{@simple_name}-#{@rpm_version}-#{@rpm_release}.#{@rpm_arch}.rpm"
      @rpm_file_basename    = File.basename( @rpm_file )

      RPM.provides[@simple_name]            = "#{@simple_name}-#{@rpm_version}-#{@rpm_release}"
      RPM.provides_rpm_path[@simple_name]   = @rpm_file

      define_tasks
    end

    def define_tasks
      desc "Build #{@simple_name} RPM."
      task "rpm:#{@simple_name}" => [ @rpm_file ]

      file @rpm_file => [ 'rpm:topdir', @spec_file ] do
        @log.info "Building package '#{@rpm_file_basename}'..."
        build_source_dependencies( @rpm_file, @rpm_version, @rpm_release )
        build_rpm
        @log.info "Package '#{@rpm_file_basename}' was built successfully."
      end

      task 'rpm:all' => [ "rpm:#{@simple_name}" ]
    end

    def build_rpm
      Dir.chdir( File.dirname( @spec_file ) ) do
        @exec_helper.execute( "rpmbuild --define '_tmppath #{@config.dir.root}/#{@config.dir.build}/tmp' --define '_topdir #{@config.dir.root}/#{@config.dir.top}/#{@config.os_path}' --target #{@rpm_arch} -ba #{@simple_name}.spec" )
      end

      Rake::Task[ 'rpm:repodata:force' ].reenable
    end

    def handle_requirement(rpm_file, requirement)
      if RPM.provides.keys.include?( requirement )
        file rpm_file  => [ RPM.provides_rpm_path[ requirement ] ]
      end
    end

    def substitute_defined_data(str, version=nil, release=nil)

      substitutes = {}

      File.open( @spec_file).each_line do |line|
        match = line.match(/^%define (\w+) (.*)$/)
        substitutes[match[1].strip] = match[2].strip if match
      end

      s = str.dup

      for key in substitutes.keys
        s.gsub!( /%\{#{key}\}/, substitutes[key] )
      end

      name = File.basename( @spec_file, ".*" )

      s.gsub!( /%\{version\}/, version ) if version
      s.gsub!( /%\{release\}/, release ) if release
      s.gsub!( /%\{name\}/, name )
      s
    end

    def handle_source(rpm_file, source, version, release)
      source = substitute_defined_data( source, version, release )

      @log.debug "Handling source '#{source}'..."

      if ( source =~ %r{https?://} or source =~ %r{ftp://} )
        handle_remote_source( rpm_file, source )
      else
        handle_local_source( rpm_file, source )
      end

      @log.debug "Source '#{source}' handled."
    end

    def handle_local_source(rpm_file, source)
      source_basename = File.basename( source )
      source_file     = "#{@config.dir.top}/#{@config.os_path}/SOURCES/#{source_basename}"

      file rpm_file => [ source_file ]

      FileUtils.cp( "#{@config.dir.src}/#{source}", "#{source_file}" ) if File.exists?( "#{@config.dir.src}/#{source}" )
      FileUtils.cp( "#{@config.dir.base}/src/#{source}", "#{source_file}" ) if File.exists?( "#{@config.dir.base}/src/#{source}" )

      raise "Source '#{source}' not handled!" unless File.exists?( source_file )
    end

    def handle_remote_source(rpm_file, source)
      source_basename = File.basename( source )

      source_file       = "#{@config.dir.top}/#{@config.os_path}/SOURCES/#{source_basename}"
      source_cache_file = "#{@config.dir.src_cache}/#{source_basename}"

      file rpm_file => [ source_file ]

      begin
        if ( ! File.exist?( source_cache_file ) )
          FileUtils.mkdir_p( @config.dir.src_cache )
          @exec_helper.execute( "wget --no-check-certificate #{source} -O #{source_cache_file}" )
        end

        FileUtils.cp( source_cache_file, source_file )
      rescue
        FileUtils.rm_rf( source_cache_file )
        FileUtils.rm_rf( source_file )
      end

      raise "Source '#{source}' not handled!" unless File.exists?( source_file )
    end

    def build_source_dependencies( rpm_file, version=nil, release=nil)
      File.open( @spec_file).each_line do |line|
        line.gsub!( /#.*$/, '' )
        if ( line =~ /Requires:(.*)/ )
          requirement = $1.strip
          handle_requirement( rpm_file, requirement )
        elsif ( line =~ /Source[0-9]*:(.*)/ )
          source = $1.strip
          handle_source( rpm_file, source, version, release  )
        elsif ( line =~ /Patch[0-9]*:(.*)/ )
          patch = $1.strip
          handle_source( rpm_file, patch, version, release  )
        end
      end
    end
  end
end

desc "Build all RPMs"
task 'rpm:all'
