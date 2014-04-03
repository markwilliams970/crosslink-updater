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