# UnMountToolsInstaller.rb
#
# Description: This method unmounts the VMware Tools CD installer as a CD-ROM for the guest
#

require 'savon'

def login(client, username, password)
  result = client.call(:login) do
    message( :_this => "SessionManager", :userName => username, :password => password )
  end
  client.globals.headers({ "Cookie" => result.http.headers["Set-Cookie"] })
end

def logout(client)
  begin
    client.call(:logout) do
      message(:_this => "SessionManager")
    end
  rescue => logouterr
    $evm.log(:error, "Error logging out #{logouterr.class} #{logouterr}")
  end
end

# Get vm object from root
vm = $evm.root['vm']
raise "VM object not found" if vm.nil?

# This method only works with VMware VMs currently
raise "Invalid vendor:<#{vm.vendor}>" unless vm.vendor.downcase == 'vmware'

$evm.log(:info,"Detected VM: #{vm.name} vendor: #{vm.vendor} provider: #{vm.ext_management_system.name} ems_ref: #{vm.ems_ref}")

# get servername and credentials from vm.ext_management_system
servername = vm.ext_management_system.ipaddress
username = vm.ext_management_system.authentication_userid
password = vm.ext_management_system.authentication_password

client = Savon.client(
  :wsdl => "https://#{servername}/sdk/vim.wsdl",
  :endpoint => "https://#{servername}/sdk/",
  :ssl_verify_mode => :none,
  :ssl_version => :TLSv1,
  :raise_errors => false,
  :log_level => :info,
  :log => false
)

#client.operations.sort.each { |operation| $evm.log(:info, "Savon Operation: #{operation}") }

# login and set cookie
login(client, username, password)

# perform UnMountToolsInstaller
unmount_tools_installer_result = client.call(:unmount_tools_installer) do
  message({ '_this' => vm.ems_ref, :attributes! => { 'type' => "VirtualMachine"} } )
end
#$evm.log(:warn, "unmount_tools_installer_result: #{unmount_tools_installer_result.inspect}")
$evm.log(:info, "unmount_tools_installer_result: #{unmount_tools_installer_result.success?}")

# logout
logout(client)
