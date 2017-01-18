platform :ios, '8.0'

target :'TripTrunk' do
    pod 'AWSAutoScaling'
    pod 'AWSCloudWatch'
    pod 'AWSCognito'
    pod 'AWSCognitoIdentityProvider'
    pod 'AWSDynamoDB'
    pod 'AWSEC2'
    pod 'AWSElasticLoadBalancing'
    pod 'AWSIoT'
    pod 'AWSKinesis'
    pod 'AWSLambda'
    pod 'AWSMachineLearning'
    pod 'AWSMobileAnalytics'
    pod 'AWSS3'
    pod 'AWSSES'
    pod 'AWSSimpleDB'
    pod 'AWSSNS'
    pod 'AWSSQS'
    pod 'GooglePlaces'
    pod 'GMImagePicker', '~> 0.0.2'
    pod 'FBSDKCoreKit'
    pod 'FBSDKLoginKit'
    pod 'FBSDKShareKit'
    pod 'Bolts'
    pod 'Google/SignIn'
    
    post_install do |installer|
        installer.pods_project.build_configuration_list.build_configurations.each do |configuration|
            configuration.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
        end  
    end
end
