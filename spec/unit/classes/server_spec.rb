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

  describe 'with no parameters' do
    it { should include_class("postgresql::server") }
  end

  describe 'with manage_firewall' do
    let(:params) do
      {
        :manage_firewall => true,
        :firewall_supported => true,
        :ensure => true,
      }
    end

    it { should include_class("postgresql::server::firewall") }
    it { should contain_firewall("5432 accept - postgres") }
  end
end
