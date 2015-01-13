require 'rubygems'
require 'json'
require 'rest_client'
require 'pp'
require 'csv'

@todoist_url = "https://www.todoist.com/TodoistSync/v5.3/get"
@api_token = "REPLACE_THIS"
# Should be converted to user name and password login, instead put the api_token from your account page here.

projects = Hash.new
labelList = Hash.new
noteList = Hash.new

if ARGV.length != 1
  puts "Please pass in the file name to write"
  exit (1)
else
  outputFileName = ARGV[0]
end

RestClient.post( @todoist_url+"?seq_no=0",:api_token => @api_token) { |response, request, result, &block|
    case response.code
      when 200

        task_details = JSON.parse response
        # pp task_details

        task_details['Projects'].each do |prj|
          projects [prj['id']] = prj['name']
        end

        task_details['Labels'].each do |lbl|
          labelList [lbl['id']] = lbl['name']
        end

        task_details['Notes'].each do |note|
          noteList [note['item_id']] = 'Y'
        end

        puts('Writing to file ' << outputFileName)
        CSV.open(outputFileName,'w') do |csv|

          csv << [ "id","content","due_date_utc","date_string","priority","checked","indent","project","labels","has note","deleted" ]
          task_details["Items"].each do |tsk|

            labelString = ''
            tsk["labels"].each do |label|
              if labelString != '' then labelString << ',' end
              labelString << labelList[label]
            end
            if noteList[tsk["id"]] == 'Y' then hasNote = 'Y' else hasNote = 'N' end

            project = tsk["project_id"]
            csv << [ tsk["id"],tsk["content"],tsk["due_date_utc"],tsk["date_string"],tsk["priority"],tsk["checked"],tsk["indent"],projects[project],labelString,hasNote,tsk["deleted"] ]

            print "Task:", tsk["id"],tsk["content"],tsk["due_date_utc"],tsk["date_string"],tsk["priority"],tsk["checked"],tsk["indent"],projects[project],labelString,tsk["deleted"],"\n"
          end
        end

    when 423
      raise "Failed"
    when 301, 302, 307
        response.follow_redirection(request, result, &block)
    else
      response.return!(request, result, &block)
    end
}






