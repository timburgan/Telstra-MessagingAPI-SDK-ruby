# frozen_string_literal: true

module Telstra_Messaging
  # HTTP client utilities extracted from ApiClient for better maintainability
  module HttpClientUtilities
    # Check if the given MIME is a JSON MIME.
    # JSON MIME examples:
    #   application/json
    #   application/json; charset=UTF8
    #   APPLICATION/JSON
    #   application/vnd.company+json
    # @param [String] mime MIME
    # @return [Boolean] True if the MIME is application/json
    def json_mime?(mime)
      (mime =~ /\Aapplication\/json/i) != nil
    end

    # Select Accept header.
    # @param [Array] accepts array for Accept
    # @return [String] the Accept header (e.g. application/json)
    def select_header_accept(accepts)
      return nil if accepts.nil? || accepts.empty?

      # use JSON when present, otherwise use the first one
      json_accept = accepts.find { |s| json_mime?(s) }
      json_accept || accepts.join(',')
    end

    # Select Content-Type header.
    # @param [Array] content_types array for Content-Type
    # @return [String] the Content-Type header  (e.g. application/json)
    def select_header_content_type(content_types)
      # use JSON when present, otherwise use the first one
      return 'application/json' if content_types.nil? || content_types.empty?

      json_content_type = content_types.find { |s| json_mime?(s) }
      json_content_type || content_types.first
    end

    # Build parameter value according to the given collection format.
    # @param [String] collection_format one of :csv, :ssv, :tsv, :pipes and :multi
    def build_collection_param(param, collection_format)
      case collection_format
      when :csv
        param.join(',')
      when :ssv
        param.join(' ')
      when :tsv
        param.join("\t")
      when :pipes
        param.join('|')
      when :multi
        # return the array directly as typhoeus will handle it as expected
        param
      else
        fail "unknown collection format: #{collection_format.inspect}"
      end
    end

    # Sanitize filename by removing path.
    # e.g. ../../sun.gif becomes sun.gif
    #
    # @param [String] filename the filename to be sanitized
    # @return [String] the sanitized filename
    def sanitize_filename(filename) = filename.gsub(%r{.*[/\\]}, '')

    def build_request_url(path)
      # Add leading and trailing slashes to path
      path = "/#{path}".gsub(%r{/+}, '/')
      URI::DEFAULT_PARSER.escape(@config.base_url + path)
    end

    private

    # Save response body into a file in (the defined) temporary folder, using the filename
    # from the "Content-Disposition" header if provided, otherwise a random filename.
    # The response body is written to the file in chunks in order to handle files which
    # size is larger than maximum Ruby String or even larger than the maximum memory a Ruby
    # process can use.
    #
    # @see Configuration#temp_folder_path
    def download_file(request)
      tempfile = nil
      encoding = nil
      request.on_headers do |response|
        content_disposition = response.headers['Content-Disposition']
        if content_disposition && content_disposition =~ /filename=/i
          filename = content_disposition[/filename=['"]?([^'"\s]+)['"]?/, 1]
          prefix = sanitize_filename(filename)
        else
          prefix = 'download-'
        end
        prefix = prefix + '-' unless prefix.end_with?('-')
        encoding = response.body.encoding
        tempfile = Tempfile.open(prefix, @config.temp_folder_path, encoding: encoding)
        @tempfile = tempfile
      end
      request.on_body do |chunk|
        chunk.force_encoding(encoding)
        tempfile.write(chunk)
      end
      request.on_complete do |response|
        tempfile.close if tempfile
        @config.logger.info "Temp file written to #{tempfile.path}, please copy the file to a proper folder "\
                            "with e.g. `FileUtils.cp(tempfile.path, '/new/file/path')` otherwise the temp file "\
                            "will be deleted automatically with GC. It's also recommended to delete the temp file "\
                            "explicitly with `tempfile.delete`"
      end
    end

    # Builds the HTTP request body
    #
    # @param [Hash] header_params Header parameters
    # @param [Hash] form_params Query parameters
    # @param [Object] body HTTP body (JSON/XML)
    # @return [String] HTTP body data in the form of string
    def build_request_body(header_params, form_params, body)
      # http form
      if header_params['Content-Type'] == 'application/x-www-form-urlencoded' ||
         header_params['Content-Type'] == 'multipart/form-data'
        data = {}
        form_params.each do |key, value|
          case value
          when ::File, ::Array, nil
            # let typhoeus handle File, Array and nil parameters
            data[key] = value
          else
            data[key] = value.to_s
          end
        end
      elsif body
        data = body.is_a?(String) ? body : body.to_json
      else
        data = nil
      end
      data
    end
  end
end