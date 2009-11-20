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

require 'cantiere/log'
require 'cantiere/helpers/exec-helper'

module Cantiere
  LOG = Log.new
  EXEC_HELPER = ExecHelper.new

  # here are global variables
  SUPPORTED_ARCHES = [ "i386", "x86_64" ]
  SUPPORTED_OSES = {
          "fedora" => [ "12", "11", "rawhide" ]
  }

  LATEST_STABLE_RELEASES = {
          "fedora" => "11",
          "rhel" => "5"
  }

  APPLIANCE_DEFAULTS = {
          "os_name" => "fedora",
          "os_version" => LATEST_STABLE_RELEASES['fedora'],
          "disk_size" => 2,
          "mem_size" => 1024,
          "network_name" => "NAT",
          "vcpu" => 1,
          "arch" => (-1.size) == 8 ? "x86_64" : "i386"
  }

  DEFAULT_PROJECT_CONFIG = {
          :name => 'Cantiere',
          :version => '1.0.0.Beta1',
          :release => 'SNAPSHOT',
          :dir_build => 'build',
          #:topdir            => "#{self.} build/topdir",
          :dir_sources_cache => 'sources-cache',
          :dir_rpms_cache => 'rpms-cache',
          :dir_specs => 'specs',
          :dir_appliances => 'appliances',
          :dir_src => 'src',
          :dir_kickstarts => 'kickstarts'
  }

  DEFAULT_HELP_TEXT = {
          :general => "See http://oddthesis.org/ for more info."
  }
end