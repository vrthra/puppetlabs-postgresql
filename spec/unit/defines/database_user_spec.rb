require 'spec_helper'

# DEPRECATED: This defined resource will be removed in the future anyway, use
# postgresql::role instead
describe 'postgresql::database_user', :type => :define do
  let :facts do
    {
      :postgres_default_version => '8.4',
      :osfamily => 'Debian',
    }
  end
  let :title do
    'test'
  end
  it { should include_class("postgresql::params") }
end
