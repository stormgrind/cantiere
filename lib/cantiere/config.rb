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

require 'cantiere/defaults'
require 'ostruct'

module Cantiere
  CONFIG_FILE = "#{ENV['HOME']}/.cantiere/config"

  class Config
    RELEASE_FILE = "/etc/redhat-release"

    def initialize( project_config = Hash.new )

      @name = project_config[:name] || DEFAULT_PROJECT_CONFIG[:name]

      @version = OpenStruct.new
      @version.version = project_config[:version] || DEFAULT_PROJECT_CONFIG[:version]
      @version.release = project_config[:release] || DEFAULT_PROJECT_CONFIG[:release]

      @dir = OpenStruct.new
      @dir.root = `pwd`.strip
      @dir.build = project_config[:dir_build] || DEFAULT_PROJECT_CONFIG[:dir_build]
      @dir.top = project_config[:dir_top] || "#{@dir.build}/topdir"
      @dir.src_cache = project_config[:dir_sources_cache] || DEFAULT_PROJECT_CONFIG[:dir_sources_cache]
      @dir.rpms_cache = project_config[:dir_rpms_cache] || DEFAULT_PROJECT_CONFIG[:dir_rpms_cache]
      @dir.specs = project_config[:dir_specs] || DEFAULT_PROJECT_CONFIG[:dir_specs]
      @dir.appliances = project_config[:dir_appliances] || DEFAULT_PROJECT_CONFIG[:dir_appliances]
      @dir.src = project_config[:dir_src] || DEFAULT_PROJECT_CONFIG[:dir_src]
      @dir.kickstarts = project_config[:dir_kickstarts] || DEFAULT_PROJECT_CONFIG[:dir_kickstarts]

      # TODO better way to get this directory
      @dir.base = "#{File.dirname( __FILE__ )}/../.."
      @dir.tmp = "#{@dir.build}/tmp"

      @arch = (-1.size) == 8 ? "x86_64" : "i386"
      @os = OpenStruct.new

      if File.exists?( RELEASE_FILE )
        release_match = File.read( RELEASE_FILE ).match(/^(.*) release ([\d\.]+) \((.*)\)$/)
        @os.full_name = release_match[1]

        case @os.full_name
          when /^Red Hat Enterprise Linux(.*)/ then
            @os.name = "rhel"
            @os.package_suffix = 'el'
          when /^Fedora$/ then
            @os.name = "fedora"
            @os.package_suffix = 'f'
        end

        @os.version = release_match[2]
        @os.main_version = @os.version.match( /^([\d]+)[\.]?(.*)?$/ )[1]
        @os.package_suffix = @os.package_suffix + @os.main_version
        @os.code_name = release_match[3]
      else
        raise "OS'es other than Fedora or Red Hat are currently unsupported"
      end

      if File.exists?( CONFIG_FILE )
        @data = YAML.load_file( CONFIG_FILE )
        raise "Your config file (#{CONFIG_FILE}) has incorrect format. Please correct it." if @data.nil?
      else
        @data = {}
      end

      @build_arch = ENV['CANTIERE_ARCH'].nil? ? @arch : ENV['CANTIERE_ARCH']
      @os_name = ENV['CANTIERE_OS_NAME'].nil? ? @os.name : ENV['CANTIERE_OS_NAME']
      @os_version = ENV['CANTIERE_OS_VERSION'].nil? ? @os.version : ENV['CANTIERE_OS_VERSION']
    end

    attr_reader :name
    attr_reader :version
    attr_reader :build_arch
    attr_reader :arch
    attr_reader :os_name
    attr_reader :os_version
    attr_reader :os
    attr_reader :dir
    attr_reader :data

    def os_path
      "#{@os.name}/#{@os.main_version}"
    end

    def build_path
      "#{@arch}/#{os_path}"
    end

    def version_with_release
      @version.version + ((@version.release.nil? or @version.release.empty?) ? "" : "-" + @version.release)
    end
  end
end
