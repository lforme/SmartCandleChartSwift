
Pod::Spec.new do |s|
  s.name             = 'SmartCandleChartSwift'
  s.version          = '1.0.0'
  s.summary          = 'A light k-line chart base on swift'

  s.description      = <<-DESC
  High performance k-line chart
  DESC

  s.homepage         = 'https://github.com/lforme/SmartCandleChartSwift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Lforme' => 'Lformeus18@Gmail.com' }
  s.source           = { :git => 'https://github.com/lforme/SmartCandleChartSwift.git', :tag => s.version.to_s }
  
  s.ios.deployment_target = '13.0'

  s.vendored_frameworks = 'Pod/SmartCandleChart.xcframework'
  
  s.frameworks = 'UIKit'
  
end
