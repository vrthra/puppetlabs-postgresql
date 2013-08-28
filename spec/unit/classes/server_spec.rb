require 'spec_helper'

describe 'postgresql::server', :type => :class do
  let :facts do
    {
      :postgres_default_version => '8.4',
      :osfamily => 'Debian',
      :concat_basedir => tmpfilename('server'),
      :kernel => 'Linux',
    }
  end
  it { should include_class("postgresql::server") }

  describe 'with manage_firewall' do
    let(:params) do
      {
        :manage_firewall => true,
      }
    end

    it { should include_class("firewall") }
  end
end
