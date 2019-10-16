# frozen_string_literal: true

def stub_projects_200
  json = File.read('spec/support/stubs/gitlab/projects_200.json')
  stub_request(:get, %r{/api/v4/groups}).to_return(status: 200, body: json)
end
