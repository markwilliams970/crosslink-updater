#include for rally json library gem
require 'rally_api'
require 'csv'
require 'logger'
require './multi_io.rb'

#Setting custom headers
$headers = RallyAPI::CustomHttpHeader.new()
$headers.name = "Artifact Crosslink Updater"
$headers.vendor = "Rally Technical Services"
$headers.version = "0.50"

# constants
$my_base_url            = "https://rally1.rallydev.com/slm"
$my_username            = "user@company.com"
$my_password            = "password"

$my_workspace           = "My Workspace"

$my_headers             = $headers
$my_page_size           = 200
$my_limit               = 50000
$wsapi_version          = "1.43"

$artifact_type          = :defect # Valid values: :hierarchicalrequirement, :defect, :testcase, etc.
$crosslink_field_name   = "CQDefectlink"
$old_server_hostname_fq = "myoldserver.company.com"
$new_server_hostname_fq = "mynewserver.company.com"
$target_cq_version      = "7.1.2"
$cq_dbid                = "mycqdb"
$record_url_prefix      = "/cqweb/#/#{$target_cq_version}/#{$cq_dbid}/RECORD/"
$record_url_suffix      = "&noframes=true&format=HTML&recordType=Defect"

def get_updated_crosslink(crosslink_id)
  return "<a href=\"http://#{$new_server_hostname_fq}#{$record_url_prefix}#{crosslink_id}#{$record_url_suffix}\">#{crosslink_id}</a>"
end

begin

  # Instantiate Logger
  log_file = File.open("crosslink_updater.log", "a")
  log_file.sync = true
  @logger = Logger.new MultiIO.new(STDOUT, log_file)

  @logger.level = Logger::INFO #DEBUG | INFO | WARNING | FATAL

  # Load (and maybe override with) my personal/private variables from a file...
  my_vars= File.dirname(__FILE__) + "/my_vars.rb"
  if FileTest.exist?( my_vars ) then require my_vars end

  #==================== Making a connection to Rally ====================
  config                  = {:base_url => $my_base_url}
  config[:username]       = $my_username
  config[:password]       = $my_password
  config[:version]        = $wsapi_version
  config[:workspace]      = $my_workspace
  config[:headers]        = $my_headers #from RallyAPI::CustomHttpHeader.new()

  @logger.info "Connecting to Rally as: #{$my_username}."
  @rally = RallyAPI::RallyRestJson.new(config)

  #==================== Querying Rally ==========================

  query_string = "(#{$crosslink_field_name} != \"\")"
  @logger.info "Querying Rally for Artifacts of type #{$artifact_type} where #{query_string}"
  artifact_fetch = "ObjectID,FormattedID,Name,#{$crosslink_field_name},Project,Name"
  @logger.info "Fetching fields: #{artifact_fetch}."

  artifact_query = RallyAPI::RallyQuery.new()
  artifact_query.type = $artifact_type
  artifact_query.fetch = artifact_fetch
  artifact_query.page_size = 200 #optional - default is 200
  artifact_query.limit = 100000 #optional - default is 99999
  artifact_query.order = "FormattedID Asc"
  artifact_query.query_string = query_string

  artifact_query_results = @rally.find(artifact_query)

  if artifact_query_results.total_result_count == 0 then
    @logger.warn "No Artifacts matching criteria #{query_string} found. Exiting."
    exit
  end

  artifact_count = artifact_query_results.total_result_count
  @logger.info "Found a total of: #{artifact_count} Artifacts to process."

  # Loop through Artifacts and update crosslink field.
  processed_count = 0

  # Reg-ex for types of crosslink

  # Example:
  # adpdb00546186
  type_id_only = /^adpdb*/

  # Example:
  # http://myserver/cqweb/restapi/7.1.0/adpdb/RECORD/adpdb00554781?format=HTML&noframes=true&recordType=Defect
  type_url_only = /^http*/

  # Example:
  # <a href="http://myserver/cqweb/#/7.1.0/adpdb/RECORD/adpdb00522935&noframes=true&format=HTML&recordType=Defect">adpdb00522935</a>
  type_full_href = /^\<a href=/

  artifact_query_results.each do | this_artifact |

    this_crosslink = this_artifact["#{$crosslink_field_name}"]
    this_new_crosslink = this_crosslink

    # Detect type of crosslink information present
    detected_match = false

    # ID only
    test_match = this_crosslink.match type_id_only
    if !test_match.nil? then
      @logger.info "Crosslink #{this_crosslink} contains ID only."
      crosslink_id = this_crosslink
      detected_match = true
    end

    # URL only
    test_match = this_crosslink.match type_url_only
    if !test_match.nil? then
      @logger.info "Crosslink #{this_crosslink} contains URL only."
      crosslink_id = this_crosslink.match /adpdb\d+/
      detected_match = true
    end

    # Full href
    test_match = this_crosslink.match type_full_href
    if !test_match.nil? then
      @logger.info "Crosslink #{this_crosslink} contains full HREF."
      crosslink_id = this_crosslink.match /adpdb\d+/
      detected_match = true
    end

    if !detected_match then
      this_formatted_id = this_artifact["FormattedID"]
      @logger.warn "Crosslink #{this_crosslink} for artifact #{this_formatted_id} does not match known patterns. Skipped."
    else
      this_new_crosslink = get_updated_crosslink(crosslink_id)

      # Try the update
      begin
        this_object_id = this_artifact["ObjectID"]
        update_fields = {}
        update_fields["#{$crosslink_field_name }"] = this_new_crosslink
        updated_artifact = @rally.update("#{$artifact_type}", this_object_id, update_fields)
        @logger.info "Artifact #{this_artifact["FormattedID"]}: crosslink updated from #{this_crosslink} to #{this_new_crosslink}."
      rescue => ex
        @logger.error "Error occurred attempting to update crosslink field: " + ex.message
        @logger.error ex.backtrace
      end
      processed_count += 1
    end
  end

  @logger.info "Done! Updated crosslink field for a total of: #{processed_count} Artifacts of type #{$artifact_type}."

end