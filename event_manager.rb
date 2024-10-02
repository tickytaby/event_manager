require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislator_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
    
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_homephone(number)
  number.gsub!(/[^\d]/, '')
  case 
  when number.length == 10
    phone = number
  when number.length < 10 
    phone = '0' * 10
  when number.length == 11 && number.split('') == '1'
    phone = number[1..]
  when number.length == 11 && number.split('') != '1'
    phone = '0' * 10 
  when number.length > 11
    phone = '0' * 10
  end
end 

puts "Event Manager Initialized!"

contents = CSV.open(
  'lib/event_attendees.csv', 
  headers: true,
  header_converters: :symbol
  )

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislator_by_zipcode(zipcode)
  phone = clean_homephone(row[:homephone])
  regtime = row[:regdate]
  puts "#{name} registered on #{regtime.split(' ')[0]} at #{regtime.split(' ')[1]}"
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end