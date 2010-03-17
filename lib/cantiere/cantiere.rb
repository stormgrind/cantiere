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

require 'rake/tasklib'
require 'cantiere/defaults'
require 'cantiere/rpm'
require 'cantiere/config'
require 'cantiere/topdir'
require 'cantiere/rpm-utils'
require 'cantiere/gpg-sign'
require 'cantiere/validator/config-validator'

module Cantiere
  class Cantiere
    def initialize( config, project_config = Hash.new )
      @log = LOG

      @config = config.nil? ? Config.new( project_config ) : config

      ConfigValidator.new( @config ).validate

      @log.debug "Current architecture: #{@config.arch}"
      @log.debug "Building architecture: #{@config.build_arch}"

      Topdir.new( @config )
      RPMUtils.new( @config )
      GPGSign.new( @config )

      [ "specs/*.spec" ].each do |spec_file_dir|
        Dir[ spec_file_dir ].each do |spec_file|
          RPM.new( @config, spec_file )
        end
      end
    end
  end
end