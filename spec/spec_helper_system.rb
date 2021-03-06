require 'rspec-system/spec_helper'
require 'rspec-system-puppet/helpers'
require 'tempfile'

module LocalHelpers
  include RSpecSystem::Util

  def psql(psql_cmd, user = 'postgres', &block)
    psql = "psql #{psql_cmd}"
    shell("su #{shellescape(user)} -c #{shellescape(psql)}", &block)
  end

  def cleanup
    # Cleanup
    psql('--command="drop database postgresql_test_db" postgres')
    pp = <<-EOS
      class { "postgresql": }->
      class { "postgresql::plperl":
        package_ensure => absent,
      }->
      class { 'postgresql::server':
        ensure => absent,
      }
    EOS
    puppet_apply(pp)
  end
end

include RSpecSystemPuppet::Helpers

RSpec.configure do |c|
  # Project root for the firewall code
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Enable colour in Jenkins
  c.tty = true

  # Include in our local helpers
  c.include ::LocalHelpers

  # Puppet helpers
  c.include RSpecSystemPuppet::Helpers
  c.extend RSpecSystemPuppet::Helpers

  # This is where we 'setup' the nodes before running our tests
  c.before :suite do
    # Install puppet
    puppet_install

    # Copy this module into the module path of the test node
    puppet_module_install(:source => proj_root, :module_name => 'postgresql')
    shell('puppet module install puppetlabs/stdlib')
    shell('puppet module install puppetlabs/firewall')
    shell('puppet module install puppetlabs/apt')
    shell('puppet module install ripienaar/concat')

    file = Tempfile.new('foo')
    begin
      file.write(<<-EOS)
---
:logger: noop
      EOS
      file.close
      rcp(:sp => file.path, :dp => '/etc/puppet/hiera.yaml')
    ensure
      file.unlink
    end
  end
end
