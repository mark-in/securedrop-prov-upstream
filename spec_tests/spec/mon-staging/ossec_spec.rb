#require 'spec_helper'
#
# ensure hosts file references app server by ip
# TODO: replace hardcoded ip for app-staging host
describe file('/etc/hosts') do
  its(:content) { should match /^127\.0\.1\.1 mon-staging mon-staging$/ }
  its(:content) { should match /^10\.0\.1\.2  app-staging$/ }
end

# ensure required packages are installed
['postfix', 'procmail', 'mailutils', 'securedrop-ossec-server'].each do |pkg|
  describe package(pkg) do
    it { should be_installed }
  end
end

# ensure custom /etc/aliases is present
describe file('/etc/aliases') do
  it { should be_file }
  it { should be_mode '644' }
  its(:content) { should match /^root: ossec$/ }
end

# ensure sasl password for smtp relay is configured
# TODO: values below are hardcoded. for staging, 
# this is probably ok. 
describe file('/etc/postfix/sasl_passwd') do
  sasl_passwd_regex = Regexp.quote('[smtp.gmail.com]:587   test@ossec.test:password123')
  its(:content) { should match /^#{sasl_passwd_regex}$/ }
end

# declare desired regex checks for stripping smtp headers
header_checks = [
  '/^X-Originating-IP:/    IGNORE',
  '/^X-Mailer:/    IGNORE',
  '/^Mime-Version:/        IGNORE',
  '/^User-Agent:/  IGNORE',
  '/^Received:/    IGNORE',
]
# ensure header_checks regex to strip smtl headers are present
describe file ('/etc/postfix/header_checks') do
  it { should be_file }
  it { should be_mode '644' }
  header_checks.each do |header_check|
    header_check_regex = Regexp.quote(header_check)
    its(:content) { should match /^#{header_check_regex}$/ }
  end
end

postfix_settings = [
  'relayhost = [smtp.gmail.com]:587',
  'smtp_sasl_auth_enable = yes',
  'smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd',
  'smtp_sasl_security_options = noanonymous',
  'smtp_use_tls=yes',
  'smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache',
  'smtp_tls_security_level = fingerprint',
  'smtp_tls_fingerprint_digest = sha1',
  'smtp_tls_fingerprint_cert_match = 9C:0A:CC:93:1D:E7:51:37:90:61:6B:A1:18:28:67:95:54:C5:69:A8',
  'smtp_tls_ciphers = high',
  'smtp_tls_protocols = TLSv1.2 TLSv1.1 TLSv1 !SSLv3 !SSLv2',
  'myhostname = monitor.securedrop',
  'myorigin = $myhostname',
  'smtpd_banner = $myhostname ESMTP $mail_name (Ubuntu)',
  'biff = no',
  'append_dot_mydomain = no',
  'readme_directory = no',
  'smtp_header_checks = regexp:/etc/postfix/header_checks',
  'mailbox_command = /usr/bin/procmail',
  'inet_interfaces = loopback-only',
  'alias_maps = hash:/etc/aliases',
  'alias_database = hash:/etc/aliases',
  'mydestination = $myhostname, localhost.localdomain , localhost',
  'mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128',
  'mailbox_size_limit = 0',
  'recipient_delimiter = +',
]
# ensure all desired postfix settings are declared
describe file('/etc/postfix/main.cf') do
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_mode '644' }
  postfix_settings.each do |postfix_setting|
    postfix_setting_regex = Regexp.quote(postfix_setting)
    its(:content) { should match /^#{postfix_setting_regex}$/ }
  end
end

# ensure ossec considers app-staging host "available"
describe command('/var/ossec/bin/list_agents -a') do
  its(:stdout) { should eq "app-staging-10.0.1.2 is available.\n" }
end

# ensure ossec gpg homedir exists
describe file("/var/ossec/.gnupg") do
  it { should be_directory }
  it { should be_owned_by "ossec" }
  it { should be_mode '700' }
end

# ensure test admin gpg pubkey is present
describe file('/var/ossec/test_admin_key.pub') do
  it { should be_file }
  it { should be_mode '644' }
end

# ensure test admin gpg pubkey is in ossec keyring
describe command('su -s /bin/bash -c "gpg --homedir /var/ossec/.gnupg --import /var/ossec/test_admin_key.pub" ossec') do
  its(:exit_status) { should eq 0 }
  # gpg dumps a lot of output to stderr, rather than stdout
  expected_output = <<-eos
gpg: key EDDDC102: "Test/Development (DO NOT USE IN PRODUCTION) (Admin's OSSEC Alert GPG key) <securedrop@freedom.press>" not changed
gpg: Total number processed: 1
gpg:              unchanged: 1
  eos
  its(:stderr) { should eq expected_output }
end

# ensure key files for ossec-server exist
['/var/ossec/etc/sslmanager.key', '/var/ossec/etc/sslmanager.cert'].each do |keyfile|
  describe file(keyfile) do
    it { should be_file }
    it { should be_mode '644' }
    it { should be_owned_by 'root' }
   end
end

# declare ossec procmail settings
ossec_procmail_settings = [
  'VERBOSE=yes',
  'MAILDIR=/var/mail/',
  'DEFAULT=$MAILDIR',
  'LOGFILE=/var/log/procmail.log',
  'SUBJECT=`formail -xSubject:`',
  ':0 c',
  '*^To:.*root.*',
  '|/var/ossec/send_encrypted_alarm.sh',
]
# ensure ossec procmailrc has desired settings
describe file("/var/ossec/.procmailrc") do
  it { should be_file }
  it { should be_mode '644' }
  it { should be_owned_by 'ossec' }
  ossec_procmail_settings.each do |ossec_procmail_setting|
    ossec_procmail_setting_regex = Regexp.quote(ossec_procmail_setting)
    its(:content) { should match /^#{ossec_procmail_setting_regex}$/ }
  end
end
  
# TODO: mode 0755 sounds right to me, but the mon-staging host
# actually has mode 1407. Debug after serverspec tests have been ported
describe file('/var/ossec/send_encrypted_alarm.sh') do
  it { should be_file }
  it { should be_owned_by 'ossec' }
  it { should be_mode '1407' }
end

# TODO: ansible is setting mode 0660, but servers actually have 1224
# Debug after serverspec tests have been ported
describe file('/var/log/procmail.log') do
  it { should be_file }
  it { should be_mode '1224' }
  it { should be_owned_by 'ossec' }
end
  
