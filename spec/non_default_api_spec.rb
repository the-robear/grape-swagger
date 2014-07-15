require 'spec_helper'

describe 'options: ' do
  context 'overriding the basepath' do
    before :all do

      class BasePathMountedApi < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleApiWithBasePath < Grape::API
        NON_DEFAULT_BASE_PATH = 'http://www.breakcoregivesmewood.com'

        mount BasePathMountedApi
        add_swagger_documentation base_path: NON_DEFAULT_BASE_PATH
      end

    end

    def app
      SimpleApiWithBasePath
    end

    # it "retrieves the given base-path on /swagger_doc" do
    #   get '/swagger_doc.json'
    #   JSON.parse(last_response.body)["basePath"].should == SimpleApiWithBasePath::NON_DEFAULT_BASE_PATH
    # end

    it 'retrieves the same given base-path for mounted-api' do
      get '/swagger_doc/something.json'
      JSON.parse(last_response.body)['basePath'].should == SimpleApiWithBasePath::NON_DEFAULT_BASE_PATH
    end
  end

  context 'overriding the basepath with a proc' do
    before :all do

      class ProcBasePathMountedApi < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleApiWithProcBasePath < Grape::API
        mount ProcBasePathMountedApi
        add_swagger_documentation base_path: proc { |request| "#{request.base_url}/some_value" }
      end
    end

    def app
      SimpleApiWithProcBasePath
    end

    # it "retrieves the given base-path on /swagger_doc" do
    #   get '/swagger_doc.json'
    #   JSON.parse(last_response.body)["basePath"].should == "http://example.org/some_value"
    # end

    it 'retrieves the same given base-path for mounted-api' do
      get '/swagger_doc/something.json'
      JSON.parse(last_response.body)['basePath'].should == 'http://example.org/some_value'
    end
  end

  context 'relative base_path' do
    before :all do

      class RelativeBasePathMountedApi < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleApiWithRelativeBasePath < Grape::API
        mount RelativeBasePathMountedApi
        add_swagger_documentation base_path: '/some_value'
      end
    end

    def app
      SimpleApiWithRelativeBasePath
    end

    # it "retrieves the given base-path on /swagger_doc" do
    #   get '/swagger_doc.json'
    #   JSON.parse(last_response.body)["basePath"].should == "http://example.org/some_value"
    # end

    it 'retrieves the same given base-path for mounted-api' do
      get '/swagger_doc/something.json'
      JSON.parse(last_response.body)['basePath'].should == 'http://example.org/some_value'
    end
  end

  context 'overriding the version' do
    before :all do

      class ApiVersionMountedApi < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleApiWithApiVersion < Grape::API
        API_VERSION = '101'

        mount ApiVersionMountedApi
        add_swagger_documentation api_version: API_VERSION
      end
    end

    def app
      SimpleApiWithApiVersion
    end

    it 'retrieves the api version on /swagger_doc' do
      get '/swagger_doc.json'
      JSON.parse(last_response.body)['apiVersion'].should == SimpleApiWithApiVersion::API_VERSION
    end

    it 'retrieves the same api version for mounted-api' do
      get '/swagger_doc/something.json'
      JSON.parse(last_response.body)['apiVersion'].should == SimpleApiWithApiVersion::API_VERSION
    end
  end

  context 'mounting in a versioned api' do
    before :all do

      class SimpleApiToMountInVersionedApi < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleApiWithVersionInPath < Grape::API
        version 'v1', using: :path

        mount SimpleApiToMountInVersionedApi
        add_swagger_documentation
      end
    end

    def app
      SimpleApiWithVersionInPath
    end

    it 'gets the documentation on a versioned path /v1/swagger_doc' do
      get '/v1/swagger_doc.json'

      JSON.parse(last_response.body).should == {
        'apiVersion' => '0.1',
        'swaggerVersion' => '1.2',
        'info' => {},
        'produces' => ['application/xml', 'application/json', 'application/vnd.api+json', 'text/plain'],
        'apis' => [
          { 'path' => '/something.{format}', 'description' => 'Operations about somethings' },
          { 'path' => '/swagger_doc.{format}', 'description' => 'Operations about swagger_docs' }
        ]
      }
    end

    it 'gets the resource specific documentation on a versioned path /v1/swagger_doc/something' do
      get '/v1/swagger_doc/something.json'
      last_response.status.should eq 200
      JSON.parse(last_response.body).should == {
        'apiVersion' => '0.1',
        'swaggerVersion' => '1.2',
        'basePath' => 'http://example.org',
        'resourcePath' => '/something',
        'produces' => ['application/xml', 'application/json', 'application/vnd.api+json', 'text/plain'],
        'apis' => [{
          'path' => '/0.1/something.{format}',
          'operations' => [{
            'notes' => '',
            'summary' => 'This gets something.',
            'nickname' => 'GET--version-something---format-',
            'method' => 'GET',
            'parameters' => [],
            'type' => 'void'
          }]
        }]
      }
    end

  end

  context 'overriding hiding the documentation paths' do
    before :all do
      class HideDocumentationPathMountedApi < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleApiWithHiddenDocumentation < Grape::API
        mount HideDocumentationPathMountedApi
        add_swagger_documentation hide_documentation_path: true
      end
    end

    def app
      SimpleApiWithHiddenDocumentation
    end

    it "it doesn't show the documentation path on /swagger_doc" do
      get '/swagger_doc.json'
      JSON.parse(last_response.body).should == {
        'apiVersion' => '0.1',
        'swaggerVersion' => '1.2',
        'info' => {},
        'produces' => ['application/xml', 'application/json', 'application/vnd.api+json', 'text/plain'],
        'apis' => [
          { 'path' => '/something.{format}', 'description' => 'Operations about somethings' }
        ]
      }
    end
  end

  context 'overriding hiding the documentation paths in prefixed API' do
    before :all do
      class HideDocumentationPathPrefixedMountedApi < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class PrefixedApiWithHiddenDocumentation < Grape::API
        prefix 'abc'
        mount HideDocumentationPathPrefixedMountedApi
        add_swagger_documentation hide_documentation_path: true
      end

    end

    def app
      PrefixedApiWithHiddenDocumentation
    end

    it "it doesn't show the documentation path on /abc/swagger_doc/something.json" do
      get '/abc/swagger_doc/something.json'
      JSON.parse(last_response.body).should == {
        'apiVersion' => '0.1',
        'swaggerVersion' => '1.2',
        'basePath' => 'http://example.org',
        'resourcePath' => '/something',
        'produces' => ['application/xml', 'application/json', 'application/vnd.api+json', 'text/plain'],
        'apis' => [{
          'path' => '/abc/something.{format}',
          'operations' => [{
            'notes' => '',
            'summary' => 'This gets something.',
            'nickname' => 'GET-abc-something---format-',
            'method' => 'GET',
            'parameters' => [],
            'type' => 'void'
          }]
        }]
      }
    end

  end

  context 'overriding hiding the documentation paths in prefixed and versioned API' do
    before :all do
      class HideDocumentationPathMountedApi2 < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class PrefixedAndVersionedApiWithHiddenDocumentation < Grape::API
        prefix 'abc'
        version 'v20', using: :path

        mount HideDocumentationPathMountedApi2

        add_swagger_documentation hide_documentation_path: true, api_version: version
      end
    end

    def app
      PrefixedAndVersionedApiWithHiddenDocumentation
    end

    it "it doesn't show the documentation path on /abc/v1/swagger_doc/something.json" do
      get '/abc/v20/swagger_doc/something.json'

      JSON.parse(last_response.body).should == {
        'apiVersion' => 'v20',
        'swaggerVersion' => '1.2',
        'basePath' => 'http://example.org',
        'resourcePath' => '/something',
        'produces' => ['application/xml', 'application/json', 'application/vnd.api+json', 'text/plain'],
        'apis' => [{
          'path' => '/abc/v20/something.{format}',
          'operations' => [{
            'notes' => nil,
            'notes' => '',
            'summary' => 'This gets something.',
            'nickname' => 'GET-abc--version-something---format-',
            'method' => 'GET',
            'parameters' => [],
            'type' => 'void'
          }]
        }]
      }
    end

  end

  context 'overriding the mount-path' do
    before :all do
      class DifferentMountMountedApi < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleApiWithDifferentMount < Grape::API
        MOUNT_PATH = '/api_doc'

        mount DifferentMountMountedApi
        add_swagger_documentation mount_path: MOUNT_PATH
      end
    end

    def app
      SimpleApiWithDifferentMount
    end

    # it "retrieves the given base-path on /api_doc" do
    #   get '/api_doc.json'
    #     JSON.parse(last_response.body)["apis"].each do |api|
    #     api["path"].should start_with SimpleApiWithDifferentMount::MOUNT_PATH
    #   end
    # end

    it 'retrieves the same given base-path for mounted-api' do
      get '/api_doc/something.json'
      JSON.parse(last_response.body)['apis'].each do |api|
        api['path'].should_not start_with SimpleApiWithDifferentMount::MOUNT_PATH
      end
    end

    it 'does not respond to swagger_doc' do
      get '/swagger_doc.json'
      last_response.status.should be == 404
    end
  end

  context 'overriding the markdown' do
    before :all do
      class MarkDownMountedApi < Grape::API
        desc 'This gets something.',
             notes: '_test_'

        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleApiWithMarkdown < Grape::API
        mount MarkDownMountedApi
        add_swagger_documentation markdown: true, info: { description: '_test_' }
      end
    end

    def app
      SimpleApiWithMarkdown
    end

    it 'parses markdown for a mounted-api' do
      get '/swagger_doc/something.json'
      JSON.parse(last_response.body)['apis'][0]['operations'][0]['notes'].should eq("<p><em>test</em></p>\n")
    end

    it 'parses markdown for swagger info' do
      get '/swagger_doc.json'
      JSON.parse(last_response.body)['info'].should eq('description' => "<p><em>test</em></p>\n")
    end
  end

  context 'prefixed and versioned API' do
    before :all do
      class VersionedMountedApi < Grape::API
        prefix 'api'
        version 'v1'

        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleApiWithVersion < Grape::API
        mount VersionedMountedApi
        add_swagger_documentation api_version: 'v1'
      end
    end

    def app
      SimpleApiWithVersion
    end

    it 'parses version and places it in the path' do
      get '/swagger_doc/something.json'

      JSON.parse(last_response.body)['apis'].each do |api|
        api['path'].should start_with '/api/v1/'
      end
    end
    

  end

  context 'when add_swagger_documentation has mount_version as true' do
    before :all do
      class VersionedMountedWithVersionApiOne < Grape::API
        prefix 'api'
        version 'v1'

        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class VersionedMountedWithVersionApiTwo < Grape::API
        prefix 'api'
        version 'v2'

        desc 'This gets something too, but different.'
        get '/something' do
          { bla: 'something too' }
        end
      end

      class SimpleApiWithMountedVersionOne < Grape::API
        mount VersionedMountedWithVersionApiOne
        add_swagger_documentation api_version: 'v1', mount_with_version: true
      end

      class SimpleApiWithMountedVersionTwo < Grape::API
        mount VersionedMountedWithVersionApiTwo
        add_swagger_documentation api_version: 'v2', mount_with_version: true
      end

      class MultipleApiVersionsHolder < Grape::API
        mount SimpleApiWithMountedVersionOne
        mount SimpleApiWithMountedVersionTwo
      end
    end

    def app
      MultipleApiVersionsHolder
    end

    it 'adds the version to the mount path' do
      get '/swagger_doc/v1/something.json'
      last_response.status.should eq 200
    end

    it 'can handle two version mounts' do
      get '/swagger_doc/v1/something.json'
      one = JSON.parse(last_response.body)

      get '/swagger_doc/v2/something.json'
      two = JSON.parse(last_response.body)

      one['apis'].each do |api|
        api['path'].should start_with '/api/v1/'
        api['operations'].first['summary'].should eq 'This gets something.'
      end

      two['apis'].each do |api|
        api['path'].should start_with '/api/v2/'
        api['operations'].first['summary'].should eq 'This gets something too, but different.'
      end
    end
  end

  context 'protected API' do
    before :all do
      class ProtectedApi < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleApiWithProtection < Grape::API
        mount ::ProtectedApi
        add_swagger_documentation
      end
    end

    def app
      SimpleApiWithProtection
    end

    # it "uses https schema in mount point" do
    #   get '/swagger_doc.json', {}, 'rack.url_scheme' => 'https'
    #   JSON.parse(last_response.body)["basePath"].should == "https://example.org:80"
    # end

    it 'uses https schema in endpoint doc' do
      get '/swagger_doc/something.json', {}, 'rack.url_scheme' => 'https'
      JSON.parse(last_response.body)['basePath'].should == 'https://example.org:80'
    end
  end

  context ':hide_format' do
    before :all do
      class HidePathsApi < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleApiWithHiddenPaths < Grape::API
        mount ProtectedApi
        add_swagger_documentation hide_format: true
      end
    end

    def app
      SimpleApiWithHiddenPaths
    end

    it 'has no formats' do
      get '/swagger_doc/something.json'
      JSON.parse(last_response.body)['apis'].each do |api|
        api['path'].should_not end_with '.{format}'
      end
    end
  end

  context 'multiple documentations' do
    before :all do
      class FirstApi < Grape::API
        desc 'This is the first API'
        get '/first' do
          { first: 'hip' }
        end

        add_swagger_documentation mount_path: '/first/swagger_doc'
      end

      class SecondApi < Grape::API
        desc 'This is the second API'
        get '/second' do
          { second: 'hop' }
        end

        add_swagger_documentation mount_path: '/second/swagger_doc'
      end

      class SimpleApiWithMultipleMountedDocumentations < Grape::API
        mount FirstApi
        mount SecondApi
      end
    end

    def app
      SimpleApiWithMultipleMountedDocumentations
    end

    it 'retrieves the first swagger-documentation on /first/swagger_doc' do
      get '/first/swagger_doc.json'
      JSON.parse(last_response.body).should == {
        'apiVersion' => '0.1',
        'swaggerVersion' => '1.2',
        'info' => {},
        'produces' => ['application/xml', 'application/json', 'application/vnd.api+json', 'text/plain'],
        'apis' => [
          { 'path' => '/first.{format}', 'description' => 'Operations about firsts' }
        ]
      }
    end

    it 'retrieves the second swagger-documentation on /second/swagger_doc' do
      get '/second/swagger_doc.json'
      JSON.parse(last_response.body).should == {
        'apiVersion' => '0.1',
        'swaggerVersion' => '1.2',
        'info' => {},
        'produces' => ['application/xml', 'application/json', 'application/vnd.api+json', 'text/plain'],
        'apis' => [
          { 'path' => '/second.{format}', 'description' => 'Operations about seconds' }
        ]
      }
    end
  end

  context ':formatting' do
    before :all do
      class JSONDefaultFormatAPI < Grape::API
        desc 'This gets something.'
        get '/something' do
          { bla: 'something' }
        end
      end

      class SimpleJSONFormattedAPI < Grape::API
        mount JSONDefaultFormatAPI
        add_swagger_documentation format: :json
      end
    end

    def app
      SimpleJSONFormattedAPI
    end

    it 'defaults to JSON format when none is specified' do
      get '/swagger_doc/something'

      -> { JSON.parse(last_response.body) }.should_not raise_error
    end

  end

  context 'documented namespace description' do
    before :all do
      class NamespaceWithDescAPI < Grape::API
        namespace :aspace, desc: 'Description for aspace' do
          desc 'This gets something.'
          get '/something' do
            { bla: 'something' }
          end
        end
        add_swagger_documentation format: :json
      end
      get '/swagger_doc'
    end

    def app
      NamespaceWithDescAPI
    end

    subject do
      JSON.parse(last_response.body)['apis'][0]
    end

    it 'shows the namespace description in the json spec' do
      expect(subject['description']).to eql('Description for aspace')
    end
  end
end
