# Copyright (C) 2014-2015 MongoDB, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'mongo/operation/list_collections/result'

module Mongo
  module Operation
    module Read

      # A MongoDB listCollections command operation.
      #
      # @example Create the listCollections command operation.
      #   Mongo::Operation::Read::ListCollections.new(db_name: 'test')
      #
      # @note A command is actually a query on the virtual '$cmd' collection.
      #
      # @param [ Hash ] spec The specifications for the command.
      #
      # @option spec :db_name [ String ] The name of the database whose list of
      #   collection names is requested.
      # @option spec :options [ Hash ] Options for the command.
      #
      # @since 2.0.0
      class ListCollections
        include Executable
        include Specifiable
        include Limited
        include ReadPreferrable

        # Execute the listCollections command operation.
        #
        # @example Execute the operation.
        #   operation.execute(context)
        #
        # @param [ Mongo::Server::Context ] context The context for this operation.
        #
        # @return [ Result ] The operation result.
        #
        # @since 2.0.0
        def execute(context)
          execute_message(context)
        end

        private

        def execute_message(context)
          context.with_connection do |connection|
            Result.new(connection.dispatch([ message(context) ])).validate!
          end
        end

        def query_coll
          Database::COMMAND
        end

        def selector
          (spec[SELECTOR] || {}).merge(
            listCollections: 1, filter: { name: { '$not' => /system\.|\$/ }}
          )
        end
      end
    end
  end
end
