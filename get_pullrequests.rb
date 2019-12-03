# require 'octokit'
require 'rest-client'
require 'json'

# fetch user information
username = 'username'
access_token = 'accesstoken'
me = 'user'

# set up output file
listfile =  "pull_requests.csv"
$list_file = File.open(listfile, 'w')
$list_file.puts('Repo, PR owner')


start_page = 0
start_pr_page = 0
per_page = 10
per_pr_page = 50
pages = start_page
pr_pages = start_pr_page
done = false
pr_done = false

done = false
# Get date info
time = Time.new

datedata = "#{time.year}-#{time.month}-#{time.day}"

# create output files - one for stats and one for specific referrers
auth_result = JSON.parse(RestClient.get('https://api.github.com/user',
                         {:params => {:oauth_token => access_token} }) )

# puts "command is #{command}"

while done == false do
  # fetch repos
  command = "https://api.github.com/users/#{username}/repos"
  repo_result = JSON.parse(RestClient.get("#{command}",
      {:params => {:oauth_token => access_token, :per_page => per_page, :page => pages} }))
  puts "number of repos is #{repo_result.size}"
  if (repo_result.size <= 0) then
     done = true
  else
    # for each repo, get the data we need
    repo_result.each do |repo|
      reponame = repo["name"]
      puts "repo #{reponame}"

      pcommand = "https://api.github.com/repos/#{username}/#{reponame}/pulls?state=all"
      pr_done = false
      pr_pages = 0
      while pr_done != true do
        pull_result = JSON.parse(RestClient.get("#{pcommand}",
             {:params => {:oauth_token => access_token, :per_page => per_pr_page, :page => pr_pages} }))
        numpulls = pull_result.size
        # if ((pull_result.size > 0) or (pull_result != nil)) then
        if (pull_result.size > 0) then
           pull_result.each do |pullr|
              prowner = pullr["user"]["login"]
              $list_file.puts("#{reponame}, #{prowner}")
           end
           # numpulls = pull_result["number"]
           puts "for #{reponame} the number of PRs is #{numpulls}"
        else
           puts "no pulls for #{reponame}"
           pr_done = true
        end
        pr_pages = pr_pages + 1
      end #pr_done
    end # results > 0
    pages = pages + 1
  end # each call
end # thanks!


