crosslink-updater
=================

A simple Ruby Script that uses rally_api to update cross-link fields that are populated by Rally's ClearQuest connector to point to a new instance of a CQ server.

Requirements:

1. Tested with Ruby 1.9.3
2. [Rally API](https://rubygems.org/gems/rally_api) 0.9.25 or higher

Usage:

Configure the my_vars.rb file with the relevant environment variables.



    # constants
	$my_base_url            = "https://rally1.rallydev.com/slm"
	$my_username            = "user@company.com"
	$my_password            = "topsecret"
	
	$my_workspace           = "My Workspace"
	
	$my_headers             = $headers
	$my_page_size           = 200
	$my_limit               = 50000
	$wsapi_version          = "1.43"
	
	$crosslink_field_name   = "CQDefectlink"
	$old_server_hostname_fq = "oldcq.mycompany.com"
	$new_server_hostname_fq = "newcq.mycompany.com"
	$target_cq_version      = "7.1.2"
	$cq_dbid                = "mycqdb"
	$record_url_prefix      = "/cqweb/#/#{$target_cq_version}/#{$cq_dbid}/RECORD/"
	$record_url_suffix      = "&noframes=true&format=HTML&recordType=Defect"

Then run the script:

    ruby crosslink_updater.rb

The script will look for any Defects with non-blank entries in the $crosslink_field_name, and will adjust the URL's to the new target.