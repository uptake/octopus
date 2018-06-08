# frozen_string_literal: true

def stub_projects_200
  json = File.read('spec/support/stubs/bitbucket/projects_200.json')
  stub_request(:get, %r{/rest/api/1.0/projects}).to_return(status: 200, body: json)
end

def stub_project_repos_200(project_key)
  json = File.read('spec/support/stubs/bitbucket/project_repos_200.json')
  stub_request(:get, %r{/rest/api/1.0/projects/#{project_key}/repos}).to_return(status: 200, body: json)
end

def stub_get_raw_200(project_key, repo_slug, path)
  stub_request(:get, %r{/rest/api/1.0/projects/#{project_key}/repos/#{repo_slug}/raw/#{path}})
    .to_return(status: 200, body: nil)
end

def stub_repo_branches_200(project_key, repo_slug)
  json = File.read('spec/support/stubs/bitbucket/project_repo_branches_200.json')
  stub_request(:get, %r{/rest/api/1.0/projects/#{project_key}/repos/#{repo_slug}/branches})
    .to_return(status: 200, body: json)
end

def stub_repo_default_branch_200(project_key, repo_slug)
  json = File.read('spec/support/stubs/bitbucket/project_repo_default_branch_200.json')
  stub_request(:get, %r{/rest/api/1.0/projects/#{project_key}/repos/#{repo_slug}/branches})
    .to_return(status: 200, body: json)
end

def stub_repo_create_branch_200(_name, project_key, repo_slug, _start_point)
  json = File.read('spec/support/stubs/bitbucket/project_repo_create_branch_200.json')
  stub_request(:post, %r{/rest/branch-utils/1.0/projects/#{project_key}/repos/#{repo_slug}/branches})
    .to_return(status: 200, body: json)
end

def stub_repo_commits_200(project_key, repo_slug)
  json = File.read('spec/support/stubs/bitbucket/project_repo_commits_200.json')
  stub_request(:get, %r{/rest/api/1.0/projects/#{project_key}/repos/#{repo_slug}/commits})
    .to_return(status: 200, body: json)
end

def stub_repo_create_commit_200(project_key, repo_slug, path)
  json = File.read('spec/support/stubs/bitbucket/project_repo_create_commit_200.json')
  stub_request(:put, %r{/rest/api/1.0/projects/#{project_key}/repos/#{repo_slug}/browse/#{path}})
    .to_return(status: 200, body: json)
end

def stub_repo_pull_requests_200(project_key, repo_slug)
  json = File.read('spec/support/stubs/bitbucket/project_repo_pull_requests_200.json')
  stub_request(:get, %r{/rest/api/1.0/projects/#{project_key}/repos/#{repo_slug}/pull-requests})
    .to_return(status: 200, body: json)
end

def stub_repo_create_pull_request_200(project_key, repo_slug)
  json = File.read('spec/support/stubs/bitbucket/project_repo_create_pull_request_200.json')
  stub_request(:post, %r{/rest/api/1.0/projects/#{project_key}/repos/#{repo_slug}/pull-requests})
    .to_return(status: 200, body: json)
end
