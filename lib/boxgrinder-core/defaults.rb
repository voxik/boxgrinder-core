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

module BoxGrinder
  # here are global variables
  SUPPORTED_ARCHES = [ "i386", "x86_64" ]

  APPLIANCE_DEFAULTS = {
          :os => {
                  :password => "boxgrinder"
          },
          :hardware => {
                  :partition => 1,
                  :memory => 256,
                  :network => "NAT",
                  :cpus => 1
          }
  }

  SUPPORTED_DESKTOP_TYPES = [ "gnome" ]

  DEFAULT_LOCATION = {
          :log => 'log/boxgrinder.log'
  }

  DEFAULT_HELP_TEXT = {
          :general => "See documentation: http://community.jboss.org/docs/DOC-14358."
  }

  DEFAULT_PROJECT_CONFIG = {
          :name           => 'BoxGrinder',
          :version        => '1.0.0.Beta2',
          :release        => 'SNAPSHOT',
          :dir_build      => 'build',
          #:topdir            => "#{self.} build/topdir",
          :dir_src_cache  => 'sources-cache',
          :dir_rpms_cache => 'rpms-cache',
          :dir_specs      => 'specs',
          :dir_appliances => 'appliances',
          :dir_src        => 'src',
          :dir_kickstarts => 'kickstarts'
  }
end
