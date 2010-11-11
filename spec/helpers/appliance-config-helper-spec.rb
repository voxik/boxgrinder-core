#
# Copyright 2010 Red Hat, Inc.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of
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

require 'boxgrinder-core/helpers/appliance-config-helper'

module BoxGrinder
  describe ApplianceConfigHelper do
    before(:all) do
      @arch = `uname -m`.chomp.strip
      @base_arch = @arch.eql?("x86_64") ? "x86_64" : "i386"
    end

    def prepare_helper(configs)
      @helper = ApplianceConfigHelper.new(configs)
    end

    it "should merge post sections in right order" do
      config_a = ApplianceConfig.new
      config_a.name = 'a'
      config_a.post['base'] = ["1_1", "1_2"]
      config_a.appliances << 'b'

      config_b = ApplianceConfig.new
      config_b.name = 'b'
      config_b.post['base'] = ["2_1", "2_2"]

      prepare_helper([config_a, config_b])
      @helper.instance_variable_set(:@appliance_config, config_a.clone)

      @helper.merge_post_operations

      config = @helper.instance_variable_get(:@appliance_config)
      config.post['base'].size.should == 4
      config.post['base'].should == ['2_1', '2_2', '1_1', '1_2']
    end

    it "should merge post sections in right order with more complicated inheritance" do
      config_a = ApplianceConfig.new
      config_a.name = 'a'
      config_a.post['base'] = ["1_1", "1_2"]
      config_a.appliances << 'b1'
      config_a.appliances << 'b2'

      config_b1 = ApplianceConfig.new
      config_b1.name = 'b1'
      config_b1.post['base'] = ["2_1", "2_2"]

      config_b2 = ApplianceConfig.new
      config_b2.name = 'b2'
      config_b2.post['base'] = ["3_1", "3_2"]

      prepare_helper([config_a, config_b1, config_b2])
      @helper.instance_variable_set(:@appliance_config, config_a.clone)

      @helper.merge_post_operations

      config = @helper.instance_variable_get(:@appliance_config)
      config.post['base'].size.should == 6
      config.post['base'].should == ['3_1', '3_2', '2_1', '2_2', '1_1', '1_2']
    end

    it "should merge post sections in right order with even more and more complicated inheritance" do
      config_a = ApplianceConfig.new
      config_a.name = 'a'
      config_a.post['base'] = ["1_1", "1_2"]
      config_a.appliances << 'b1'
      config_a.appliances << 'b2'

      config_b1 = ApplianceConfig.new
      config_b1.name = 'b1'
      config_b1.appliances << 'c1'
      config_b1.post['base'] = ["2_1", "2_2"]

      config_b2 = ApplianceConfig.new
      config_b2.name = 'b2'
      config_b2.appliances << 'c2'
      config_b2.post['base'] = ["3_1", "3_2"]

      config_c1 = ApplianceConfig.new
      config_c1.name = 'c1'
      config_c1.post['base'] = ["4_1", "4_2"]

      config_c2 = ApplianceConfig.new
      config_c2.name = 'c2'
      config_c2.post['base'] = ["5_1", "5_2"]

      prepare_helper([
                         config_a,
                         config_b1,
                         config_c1,
                         config_b2,
                         config_c2
                     ])
      @helper.instance_variable_set(:@appliance_config, config_a.clone)

      @helper.merge_post_operations

      config = @helper.instance_variable_get(:@appliance_config)
      config.post['base'].size.should == 10
      config.post['base'].should == ['5_1', '5_2', '3_1', '3_2', '4_1', '4_2', '2_1', '2_2', '1_1', '1_2']
    end

    it "should merge post sections when dependent appliance has post section for platform for which we haven't specified post operations" do
      config_a = ApplianceConfig.new
      config_a.name = 'a'
      config_a.post['base'] = ["1_1", "1_2"]
      config_a.appliances << 'b'

      config_b = ApplianceConfig.new
      config_b.name = 'b'
      config_b.post['ec2'] = ["2_1", "2_2"]

      prepare_helper([config_a, config_b])
      @helper.instance_variable_set(:@appliance_config, config_a.clone)

      @helper.merge_post_operations

      config = @helper.instance_variable_get(:@appliance_config)
      config.post['base'].size.should == 2
      config.post['base'].should == ['1_1', '1_2']
      config.post['ec2'].size.should == 2
      config.post['ec2'].should == ['2_1', '2_2']
    end

    it "should merge partitions for default fs_types without options for Fedora 13 (ext4)" do
      config_a = ApplianceConfig.new
      config_a.name = 'a'
      config_a.appliances << 'b'
      config_a.hardware.partitions = {"/" => {'size' => '2'}}
      config_a.os.name = 'fedora'
      config_a.os.version = '13'

      config_b = ApplianceConfig.new
      config_b.name = 'b'
      config_b.hardware.partitions = {"/" => {'size' => '4'}, "/home" => {'size' => '2'}}
      config_b.os.name = 'fedora'
      config_b.os.version = '13'

      prepare_helper([config_a, config_b])
      @helper.instance_variable_set(:@appliance_config, config_a.clone)

      @helper.merge_partitions

      config = @helper.instance_variable_get(:@appliance_config)
      config.hardware.partitions.size.should == 2
      config.hardware.partitions.should == {"/" => {'size' => '4', 'type' => 'ext4'}, "/home" => {'size' => '2', 'type' => 'ext4'}}
    end

    it "should merge partitions for default fs_types without options for Fedora 13 (ext4) and specified options" do
      config_a = ApplianceConfig.new
      config_a.name = 'a'
      config_a.appliances << 'b'
      config_a.hardware.partitions = {"/" => {'size' => '2'}}
      config_a.os.name = 'fedora'
      config_a.os.version = '13'

      config_b = ApplianceConfig.new
      config_b.name = 'b'
      config_b.hardware.partitions = {"/" => {'size' => '4', 'options' => 'barrier=0,nodelalloc,nobh,noatime'}, "/home" => {'size' => '2'}}
      config_b.os.name = 'fedora'
      config_b.os.version = '13'

      prepare_helper([config_a, config_b])
      @helper.instance_variable_set(:@appliance_config, config_a.clone)

      @helper.merge_partitions

      config = @helper.instance_variable_get(:@appliance_config)
      config.hardware.partitions.size.should == 2
      config.hardware.partitions.should == {"/" => {'size' => '4', 'type' => 'ext4', "options"=>"barrier=0,nodelalloc,nobh,noatime"}, "/home" => {'size' => '2', 'type' => 'ext4'}}
    end

    it "should merge partitions for default fs_types without options for Fedora 11 (ext3)" do
      config_a = ApplianceConfig.new
      config_a.name = 'a'
      config_a.appliances << 'b'
      config_a.hardware.partitions = {"/" => {'size' => '2'}}
      config_a.os.name = 'fedora'
      config_a.os.version = '11'

      config_b = ApplianceConfig.new
      config_b.name = 'b'
      config_b.hardware.partitions = {"/" => {'size' => '4'}, "/home" => {'size' => '2'}}
      config_b.os.name = 'fedora'
      config_b.os.version = '11'

      prepare_helper([config_a, config_b])
      @helper.instance_variable_set(:@appliance_config, config_a.clone)

      @helper.merge_partitions

      config = @helper.instance_variable_get(:@appliance_config)
      config.hardware.partitions.size.should == 2
      config.hardware.partitions.should == {"/" => {'size' => '4', 'type' => 'ext3'}, "/home" => {'size' => '2', 'type' => 'ext3'}}
    end

    it "should merge partitions with different filesystem types" do
      config_a = ApplianceConfig.new
      config_a.name = 'a'
      config_a.appliances << 'b'
      config_a.hardware.partitions = {"/" => {'size' => '2', 'type' => 'ext4'}}
      config_a.os.name = 'fedora'
      config_a.os.version = '12'

      config_b = ApplianceConfig.new
      config_b.name = 'b'
      config_b.hardware.partitions = {"/" => {'size' => '4', 'type' => 'ext3'}, "/home" => {'size' => '2'}}
      config_b.os.name = 'fedora'
      config_b.os.version = '11'

      prepare_helper([config_a, config_b])
      @helper.instance_variable_set(:@appliance_config, config_a.clone)

      @helper.merge_partitions

      config = @helper.instance_variable_get(:@appliance_config)
      config.hardware.partitions.size.should == 2
      config.hardware.partitions.should == {"/" => {'size' => '4', 'type' => 'ext4'}, "/home" => {'size' => '2', 'type' => 'ext3'}}
    end

    it "should merge partitions with different options" do
      config_a = ApplianceConfig.new
      config_a.name = 'a'
      config_a.appliances << 'b'
      config_a.hardware.partitions = {"/" => {'size' => '2', 'type' => 'ext4', 'options' => 'barrier=0,nodelalloc,nobh,noatime'}}
      config_a.os.name = 'fedora'
      config_a.os.version = '13'

      config_b = ApplianceConfig.new
      config_b.name = 'b'
      config_b.hardware.partitions = {"/" => {'size' => '4', 'type' => 'ext3', 'options' => 'shouldnt appear'}, "/home" => {'size' => '2'}}
      config_b.os.name = 'fedora'
      config_b.os.version = '13'

      prepare_helper([config_a, config_b])
      @helper.instance_variable_set(:@appliance_config, config_a.clone)

      @helper.merge_partitions

      config = @helper.instance_variable_get(:@appliance_config)
      config.hardware.partitions.size.should == 2
      config.hardware.partitions.should == {"/" => {'size' => '4', 'type' => 'ext4', 'options' => 'barrier=0,nodelalloc,nobh,noatime'}, "/home" => {'size' => '2', 'type' => 'ext4'}}
    end

    it "should merge partitions with different options, another case where type is changing - options should be vanished" do
      config_a = ApplianceConfig.new
      config_a.name = 'a'
      config_a.appliances << 'b'
      config_a.hardware.partitions = {"/" => {'size' => '2', 'type' => 'ext4'}}
      config_a.os.name = 'fedora'
      config_a.os.version = '13'

      config_b = ApplianceConfig.new
      config_b.name = 'b'
      config_b.hardware.partitions = {"/" => {'size' => '4', 'type' => 'ext3', 'options' => 'shouldnt appear'}, "/home" => {'size' => '2'}}
      config_b.os.name = 'fedora'
      config_b.os.version = '13'

      prepare_helper([config_a, config_b])
      @helper.instance_variable_set(:@appliance_config, config_a.clone)

      @helper.merge_partitions

      config = @helper.instance_variable_get(:@appliance_config)
      config.hardware.partitions.size.should == 2
      config.hardware.partitions.should == {"/" => {'size' => '4', 'type' => 'ext4'}, "/home" => {'size' => '2', 'type' => 'ext4'}}
    end

    it "should substitute variables in repos" do
      config_a = ApplianceConfig.new
      config_a.name = 'a'
      config_a.os.name = 'fedora'
      config_a.os.version = '12'
      config_a.repos << {'name' => '#ARCH#', 'baseurl' => '#BASE_ARCH#', 'mirrorlist' => '#OS_NAME#-#OS_VERSION#'}
      config_a.init_arch

      prepare_helper([config_a])
      @helper.instance_variable_set(:@appliance_config, config_a.clone)

      @helper.merge_variables
      @helper.merge_repos

      config = @helper.instance_variable_get(:@appliance_config)
      config.repos.size.should == 1
      config.repos.first.should == {'name' => "#{@arch}", 'baseurl' => "#{@base_arch}", 'mirrorlist' => 'fedora-12'}
    end

    it "should substitute variables in post section" do
      config_a = ApplianceConfig.new
      config_a.name = 'a'
      config_a.os.name = 'fedora'
      config_a.os.version = '12'
      config_a.post['base'] = ['#ARCH#', '#BASE_ARCH#', '#OS_VERSION#', '#OS_NAME#']
      config_a.post['ec2'] = ['#ARCH#', '#BASE_ARCH#', '#OS_VERSION#', '#OS_NAME#']
      config_a.init_arch

      prepare_helper([config_a])
      @helper.instance_variable_set(:@appliance_config, config_a.clone)

      @helper.merge_variables
      @helper.merge_post_operations

      config = @helper.instance_variable_get(:@appliance_config)
      config.post.size.should == 2
      config.post['base'].should == [@arch, @base_arch, '12', 'fedora']
      config.post['ec2'].should == [@arch, @base_arch, '12', 'fedora']
    end

    it "should substitute custom variables" do
      config_a = ApplianceConfig.new
      config_a.name = 'a'
      config_a.os.name = 'fedora'
      config_a.os.version = '12'
      config_a.variables['CUSTOM_A'] = "AAA"
      config_a.variables['CUSTOM_B'] = "BBB"
      config_a.post['base'] = ['#ARCH#', '#BASE_ARCH#', '#OS_VERSION#', '#OS_NAME#', '#CUSTOM_A#', '#CUSTOM_B#']
      config_a.init_arch

      prepare_helper([config_a])
      @helper.instance_variable_set(:@appliance_config, config_a.clone)

      @helper.merge_variables
      @helper.merge_post_operations

      config = @helper.instance_variable_get(:@appliance_config)
      config.post.size.should == 1
      config.post['base'].should == [@arch, @base_arch, '12', 'fedora', 'AAA', 'BBB']
    end

    describe ".merge_default_repos" do
      it "should set default_repos option to true when not specified" do
        config_a = ApplianceConfig.new
        config_a.name = 'a'
        config_a.appliances << 'b'

        config_b = ApplianceConfig.new
        config_b.name = 'b'

        prepare_helper([config_a, config_b])
        @helper.instance_variable_set(:@appliance_config, config_a.clone)

        @helper.merge_default_repos

        config = @helper.instance_variable_get(:@appliance_config)
        config.default_repos.should == true
      end

      it "should merge default_repos option on last appliance" do
        config_a = ApplianceConfig.new
        config_a.name = 'a'
        config_a.appliances << 'b'
        config_a.default_repos = false

        config_b = ApplianceConfig.new
        config_b.name = 'b'

        prepare_helper([config_a, config_b])
        @helper.instance_variable_set(:@appliance_config, config_a.clone)

        @helper.merge_default_repos

        config = @helper.instance_variable_get(:@appliance_config)
        config.default_repos.should == false
      end

      it "should merge default_repos option on first appliance" do
        config_a = ApplianceConfig.new
        config_a.name = 'a'
        config_a.appliances << 'b'

        config_b = ApplianceConfig.new
        config_b.name = 'b'
        config_b.default_repos = false

        prepare_helper([config_a, config_b])
        @helper.instance_variable_set(:@appliance_config, config_a.clone)

        @helper.merge_default_repos

        config = @helper.instance_variable_get(:@appliance_config)
        config.default_repos.should == false
      end
    end
  end
end
