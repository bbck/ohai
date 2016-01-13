#
# Author:: Benjamin Black (<bb@chef.io>)
# Copyright:: Copyright (c) 2009-2016 Chef Software, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Ohai.plugin(:Filesystem) do
  provides "filesystem"

  collect_data(:darwin) do
    fs = Mash.new

    block_size = 0
    so = shell_out("df -i")
    so.stdout.lines do |line|
      case line
      when /^Filesystem\s+(\d+)-/
        block_size = $1.to_i
        next
      when /^(.+?)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+\%)\s+(\d+)\s+(\d+)\s+(\d+%)\s+(.+)$/
        filesystem = $1
        fs[filesystem] = Mash.new
        fs[filesystem][:block_size] = block_size
        # To match linux, these should be strings, but we don't want
        # to break back compat so we'll leave them as they are. In filesystem2
        # we make them consistent.
        fs[filesystem][:kb_size] = $2.to_i / (1024 / block_size)
        fs[filesystem][:kb_used] = $3.to_i / (1024 / block_size)
        fs[filesystem][:kb_available] = $4.to_i / (1024 / block_size)
        fs[filesystem][:percent_used] = $5
        fs[filesystem][:inodes_used] = $6
        fs[filesystem][:inodes_available] = $7
        fs[filesystem][:total_inodes] = ($6.to_i + $7.to_i).to_s
        fs[filesystem][:mount] = $9
      end
    end

    so = shell_out("mount")
    so.stdout.lines do |line|
      if line =~ /^(.+?) on (.+?) \((.+?), (.+?)\)$/
        filesystem = $1
        fs[filesystem] = Mash.new unless fs.has_key?(filesystem)
        fs[filesystem][:mount] = $2
        fs[filesystem][:fs_type] = $3
        fs[filesystem][:mount_options] = $4.split(/,\s*/)
      end
    end

    filesystem fs
  end
end
