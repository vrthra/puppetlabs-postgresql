require 'spec_helper_system'

describe 'with firewall:' do
  after :all do
    # Cleanup after tests have ran
    puppet_apply("class { 'postgresql::server': ensure => absent, package_ensure => 'absent' }") do |r|
      r.exit_code.should_not == 1
    end
  end

  context 'test installing postgresql with firewall management on' do
    it 'perform installation and make sure it is idempotent' do
      pp = <<-EOS
        class { "postgresql":
          manage_firewall => true,
        }->
        class { "postgresql::server": }
      EOS

      puppet_apply(pp) do |r|
        r.exit_code.should == 2
        r.refresh
        r.exit_code.should == 0
      end
    end
  end
end
