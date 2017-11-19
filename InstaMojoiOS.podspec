
Pod::Spec.new do |s|
  s.name = "InstaMojoiOS"
  s.version = "0.0.2"
  s.author  = { "Shardool" => "shardool@devsupport.ai" }
  s.summary = "Seemlessly Implement Payment Flow in your application"
  s.description = "Use this framework for integrating Payment SDK in your app"
  s.homepage = "https://www.instamojo.com"
  s.license  = { :type => 'Copyright', :text => 'Copyright 2017 Shubhakeerti' }
  s.platform = :ios , "8.0"
  s.ios.deployment_target = "8.0"
  s.preserve_paths = "InstaMojoiOS-Release-iphoneuniversal/InstaMojoiOS.framework"
  s.source = { :http => "https://github.com/shardullavekar/InstamojoiOS/raw/0.0.2/InstaMojo-0.0.2.tar.gz"}
  s.ios.vendored_frameworks = "InstaMojoiOS-Release-iphoneuniversal/InstaMojoiOS.framework"
end