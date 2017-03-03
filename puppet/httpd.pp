if( $facts['osfamily'] == 'RedHat' ) or ($facts['osfamily'] == 'debian'){
	$http_file='/etc/httpd/conf/httpd.conf'
	file { 'httpd.conf' :
		path => "$http_file",
		content => file('/opt/puppetlabs/puppet/code/environments/production/conf_files/apache/http.conf'),
	}                                                                      
}
