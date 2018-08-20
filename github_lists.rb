require 'octokit'
require 'rest-client'
require 'json'

# fetch user information
username = 'putnamehere'
access_token = 'settings-devsettings-personalaccesstokens'
me = 'myname'

start_page = 0
per_page = 10
pages = start_page
done = false
count = 0

# create output files - one for stats and one for specific referrers
statsfile = File.open("#{username}_stats.csv", "w")
refsfile = File.open("#{username}_referrers.csv", "w")
statsfile.puts "count, user, repo, views, clones, watchers"
refsfile.puts "user, repo, referrer, unique views"
auth_result = JSON.parse(RestClient.get('https://api.github.com/user',
                         {:params => {:oauth_token => access_token} }) )

# keep going until we are out of data
while done == false do
  # fetch repos
  command = "https://api.github.com/users/#{username}/repos"
  repo_result = JSON.parse(RestClient.get("#{command}",
      {:params => {:oauth_token => access_token, :per_page => per_page, :page => pages} }))
  if (repo_result.length <= 0) then
     done = true
  else
    # for each repo, get the data we need
    repo_result.each do |repo|
      repo_name = repo["name"]
      location = start_page * per_page + count 
      puts "#{location}: #{repo_name}"

      # watchers
      command = "https://api.github.com/repos/#{username}/#{repo_name}/watchers"
      watch_result = JSON.parse(RestClient.get("#{command}",
                              {:params => {:oauth_token => access_token}}))
      num_watchers = watch_result.length
      watchlist = "#{num_watchers}"
      if (num_watchers > 0) then
        watch_result.each do |watchers|
          watcher = watchers["login"]
          watchlist = watchlist + " #{watcher}"
        end
      end

      # let's put a try/catch here because it looks like i cannot see all of these repos
      num_clones = 0
      num_views = 0
      num_watchers = 0

      begin

      # clones 
      command = "https://api.github.com/repos/#{username}/#{repo_name}/traffic/clones"
      clone_result = JSON.parse(RestClient.get("#{command}",
                              {:params => {:oauth_token => access_token}}))
      num_clones = clone_result.length

      # referrers 
      command = "https://api.github.com/repos/#{username}/#{repo_name}/traffic/popular/referrers"
      refer_result = JSON.parse(RestClient.get("#{command}",
                              {:params => {:oauth_token => access_token}}))      
      referrers = refer_result.length
      if (refer_result.length > 0) then
        refer_result.each do |refer|
          referral = refer["referrer"]
          uniques = refer["uniques"]
          # write one line per file for each ref, could be multiple in one repo
          refsfile.puts "#{username}, #{repo_name}, #{referral}, #{uniques}"
        end # each referrer
      end  # there are referrers

      # views 
      command = "https://api.github.com/repos/#{username}/#{repo_name}/traffic/views"
      views_result = JSON.parse(RestClient.get("#{command}",
                              {:params => {:oauth_token => access_token}}))
      num_views = views_result.length

      # hop out here if we had a problem - everything was preset to zero
      rescue Exception => e
         puts "[error] API error in repo #{repo_name}: #{e}"
      end

      # write to generic stat file  
      statsfile.puts "#{location}, #{username}, #{repo_name}, #{num_views}, #{num_clones}, #{watchlist}"
      count = count + 1
    end # results > 0
    pages = pages + 1
  end # each call
end # thanks!


