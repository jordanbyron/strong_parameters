["3.1", "3.2"].each do |version|
  appraise "rails#{version}" do
    version = "~> #{version}.0"
    gem "actionpack", version
    gem "activemodel", version
    gem "railties", version
  end
end
