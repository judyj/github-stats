# require 'octokit'
require 'rest-client'
require 'json'

# fetch user information
username = 'nameoftherepo'
access_token = 'tokengoeshere'
me = 'nameoftheuser'

start_page = 0
per_page = 10
pages = start_page
done = false
count = 0
# Get date info
time = Time.new

# puts "Current Time : " + time.inspect
datedata = "#{time.year}-#{time.month}-#{time.day}"

# create output files - one for stats and one for specific referrers
statsfile = File.open("#{username}_stats#{datedata}.csv", "w")
refsfile = File.open("#{username}_referrers#{datedata}.csv", "w")
clonesfile = File.open("#{username}_cloners#{datedata}.csv", "w")
viewsfile = File.open("#{username}_viewers#{datedata}.csv", "w")
statsfile.puts "count, user, repo, views, clones, watchers"
refsfile.puts "user, repo, referrer, unique views"
clonesfile.puts "user, repo, time, clones, unique"
viewsfile.puts "user, repo, time, views, unique"
auth_result = JSON.parse(RestClient.get('https://api.github.com/user',
                         {:params => {:oauth_token => access_token} }) )

# puts "command is #{command}"

while done == false do
  # fetch repos
  command = "https://api.github.com/users/#{username}/repos"
  repo_result = JSON.parse(RestClient.get("#{command}",
      {:params => {:oauth_token => access_token, :per_page => per_page, :page => pages} }))
  # puts "number of repos is #{repo_result.length}"
  # puts "page #{pages}"
  if (repo_result.length <= 0) then
     done = true
  else
    # for each repo, get the data we need
    repo_result.each do |repo|
      repo_name = repo["name"]
      location = start_page * per_page + count 
      puts "#{location}: #{repo_name}"

      # get the generic repo data
      command = "https://api.github.com/repos/#{username}/#{repo_name}"
      repo_result = JSON.parse(RestClient.get("#{command}",
                              {:params => {:oauth_token => access_token}}))
      num_watchers = repo_result["watchers"]
      # puts "number of watchers is #{num_watchers}"

      # watchers
      command = "https://api.github.com/repos/#{username}/#{repo_name}/watchers"
      watch_result = JSON.parse(RestClient.get("#{command}",
                              {:params => {:oauth_token => access_token}}))
      num_watchers = watch_result.length
      watchlist = "#{num_watchers}"
      # puts "watchers #{num_watchers}"
      if (num_watchers > 0) then
        watch_result.each do |watchers|
          watcher = watchers["login"]
          watchlist = watchlist + " #{watcher}"
        end
      end
      # puts watchlist

      # let's put a try/catch here because it looks like i cannot see all of these repos
      num_clones = 0
      num_views = 0
      num_watchers = 0

      begin

 
      # referrers 
      # GET /repos/:owner/:repo/traffic/popular/referrers
      command = "https://api.github.com/repos/#{username}/#{repo_name}/traffic/popular/referrers"
      refer_result = JSON.parse(RestClient.get("#{command}",
                              {:params => {:oauth_token => access_token}}))      
      referrers = refer_result.length
      # puts "number of referrers is #{referrers}"
      if (refer_result.length > 0) then
        refer_result.each do |refer|
          referral = refer["referrer"]
          uniques = refer["uniques"]
          # puts "number of referrals is #{referral} (unique #{uniques})" 
          refsfile.puts "#{username}, #{repo_name}, #{referral}, #{uniques}"
        end # each referrer
      end  # there are referrers

      # views 
      command = "https://api.github.com/repos/#{username}/#{repo_name}/traffic/views"
      views_result = JSON.parse(RestClient.get("#{command}",
                              {:params => {:oauth_token => access_token}}))
      puts "views result is #{views_result}"
      views_list = views_result["views"]
      num_views = views_result["count"]
      if (num_views > 0) then
         views_list.each do |view|
           puts "view is #{view}"
           time = view["timestamp"]
           views = view["count"]
           uniques = view["uniques"]
           puts "views is #{time} #{views} (unique #{uniques})" 
           viewsfile.puts "#{username}, #{repo_name}, #{time}, #{views}, #{uniques}"
         end # each view
      end  # views list

      # hop out here if we had a problem
      rescue Exception => e
         puts "[error] API error in repo #{repo_name}: #{e}"
      end

     # clones 
      # GET /repos/:owner/:repo/traffic/clones
      command = "https://api.github.com/repos/#{username}/#{repo_name}/traffic/clones"
      clone_result = JSON.parse(RestClient.get("#{command}",
                              {:params => {:oauth_token => access_token}}))
      puts "clone result #{clone_result}"
      num_clones = clone_result["count"]
      puts "number of clones is #{num_clones}"
      clone_list = clone_result["clones"]
      puts "clone_list #{clone_list}"
      if (num_clones > 0) then
         clone_list.each do |clone|
           puts "clone is #{clone}"
           time = clone["timestamp"]
           clones = clone["count"]
           uniques = clone["uniques"]
           puts "number of clones is #{time} (unique #{uniques})" 
           clonesfile.puts "#{username}, #{repo_name}, #{time}, #{clones}, #{uniques}"
         end # each clone
      end  # there are clones

      # write to file  
      statsfile.puts "#{location}, #{username}, #{repo_name}, #{num_views}, #{num_clones}, #{watchlist}"
      count = count + 1
    end # results > 0
    pages = pages + 1
  end # each call
end # thanks!


