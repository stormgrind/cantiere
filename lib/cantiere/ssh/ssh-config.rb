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

require 'cantiere/validator/errors'
require 'yaml'

module Cantiere
  class SSHConfig
    def initialize( config )
      @config = config
      @options = {}

      # defaults
      @options['sftp_create_path']          = true
      @options['sftp_overwrite']            = false
      @options['sftp_default_permissions']  = 0644

      raise ValidationError, "Specified configuration file (#{CONFIG_FILE}) doesn't exists. #{DEFAULT_HELP_TEXT[:general]}" unless File.exists?( CONFIG_FILE )

      @config_file = YAML.load_file( CONFIG_FILE )

      validate
    end

    def validate
      raise ValidationError, "Your config file (#{CONFIG_FILE}) has incorrect format. Please correct it." if @config_file.nil?
      raise ValidationError, "No 'ssh' section in config file in configuration file '#{CONFIG_FILE}'. #{DEFAULT_HELP_TEXT[:general]}" if @config_file['ssh'].nil?

      # we need only ssh section
      @cfg = @config_file['ssh']

      raise ValidationError, "Host not specified in configuration file '#{CONFIG_FILE}' in ssh section. #{DEFAULT_HELP_TEXT[:general]}" if @cfg['host'].nil?
      raise ValidationError, "Username not specified in configuration file '#{CONFIG_FILE}' in ssh section. #{DEFAULT_HELP_TEXT[:general]}" if @cfg['username'].nil?

      @options['host']      = @cfg['host']
      @options['username']  = @cfg['username']
      @options['password']  = @cfg['password']
    end

    attr_reader :options
    attr_reader :cfg 
  end
end