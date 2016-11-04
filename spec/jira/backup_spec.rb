require 'spec_helper'

describe Jira::Backup do
  it 'has a version number' do
    expect(Jira::Backup::VERSION).not_to be nil
  end
end
