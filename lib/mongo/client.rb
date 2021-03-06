# Copyright (C) 2014-2015 MongoDB, Inc.
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Mongo

  # The client is the entry point to the driver and is the main object that
  # will be interacted with.
  #
  # @since 2.0.0
  class Client
    extend Forwardable

    # @return [ Mongo::Cluster ] cluster The cluster of servers for the client.
    attr_reader :cluster

    # @return [ Mongo::Database ] database The database the client is operating on.
    attr_reader :database

    # @return [ Hash ] options The configuration options.
    attr_reader :options

    # Delegate command execution to the current database.
    def_delegators :@database, :command

    # Determine if this client is equivalent to another object.
    #
    # @example Check client equality.
    #   client == other
    #
    # @param [ Object ] other The object to compare to.
    #
    # @return [ true, false ] If the objects are equal.
    #
    # @since 2.0.0
    def ==(other)
      return false unless other.is_a?(Client)
      cluster == other.cluster && options == other.options
    end
    alias_method :eql?, :==

    # Get a collection object for the provided collection name.
    #
    # @example Get the collection.
    #   client[:users]
    #
    # @param [ String, Symbol ] collection_name The name of the collection.
    # @param [ Hash ] options The options to the collection.
    #
    # @return [ Mongo::Collection ] The collection.
    #
    # @since 2.0.0
    def [](collection_name, options = {})
      database[collection_name, options]
    end

    # Get the hash value of the client.
    #
    # @example Get the client hash value.
    #   client.hash
    #
    # @return [ Integer ] The client hash value.
    #
    # @since 2.0.0
    def hash
      [cluster, options].hash
    end

    # Instantiate a new driver client.
    #
    # @example Instantiate a single server or mongos client.
    #   Mongo::Client.new([ '127.0.0.1:27017' ])
    #
    # @example Instantiate a client for a replica set.
    #   Mongo::Client.new([ '127.0.0.1:27017', '127.0.0.1:27021' ])
    #
    # @param [ Array<String>, String ] addresses_or_uri The array of server addresses in the
    #   form of host:port or a MongoDB URI connection string.
    # @param [ Hash ] options The options to be used by the client.
    #
    # @option options [ Symbol ] :auth_mech The authentication mechanism to
    #   use. One of :mongodb_cr, :mongodb_x509, :plain, :scram
    # @option options [ String ] :auth_source The source to authenticate from.
    # @option options [ Symbol ] :connect The connection method to use. This
    #   forces the cluster to behave in the specified way instead of
    #   auto-discovering. One of :direct, :replica_set, :sharded
    # @option options [ String ] :database The database to connect to.
    # @option options [ Hash ] :auth_mech_properties
    # @option options [ Float ] :heartbeat_frequency The number of seconds for
    #   the server monitor to refresh it's description via ismaster.
    # @option options [ Integer ] :local_threshold The local threshold boundary
    #   in seconds for selecting a near server for an operation.
    # @option options [ Integer ] :server_selection_timeout The timeout in seconds
    #   for selecting a server for an operation.
    # @option options [ String ] :password The user's password.
    # @option options [ Integer ] :max_pool_size The maximum size of the
    #   connection pool.
    # @option options [ Integer ] :min_pool_size The minimum size of the
    #   connection pool.
    # @option options [ Float ] :wait_queue_timeout The time to wait, in
    #   seconds, in the connection pool for a connection to be checked in.
    # @option options [ Float ] :connect_timeout The timeout, in seconds, to
    #   attempt a connection.
    # @option options [ Symbol ] :read The read preference options. :mode can
    #   be one of :secondary, :secondary_preferred, :primary,
    #   :primary_preferred, :nearest.
    # @option options [ Array<Hash, String> ] :roles The list of roles for the
    #   user.
    # @option options [ Symbol ] :replica_set The name of the replica set to
    #   connect to. Servers not in this replica set will be ignored.
    # @option options [ true, false ] :ssl Whether to use SSL.
    # @option options [ String ] :ssl_cert The certificate file used to identify
    #   the connection against MongoDB.
    # @option options [ String ] :ssl_key The private keyfile used to identify the
    #   connection against MongoDB. Note that even if the key is stored in the same
    #   file as the certificate, both need to be explicitly specified.
    # @option options [ String ] :ssl_key_pass_phrase A passphrase for the private key.
    # @option options [ true, false ] :ssl_verify Whether or not to do peer certification
    #   validation.
    # @option options [ String ] :ssl_ca_cert The file containing a set of concatenated
    #   certification authority certifications used to validate certs passed from the
    #   other end of the connection. Required for :ssl_verify.
    # @option options [ Float ] :socket_timeout The timeout, in seconds, to
    #   execute operations on a socket.
    # @option options [ String ] :user The user name.
    # @option options [ Hash ] :write The write concern options. Can be :w =>
    #   Integer, :fsync => Boolean, :j => Boolean.
    #
    # @since 2.0.0
    def initialize(addresses_or_uri, options = {})
      if addresses_or_uri.is_a?(::String)
        create_from_uri(addresses_or_uri, options)
      else
        create_from_addresses(addresses_or_uri, options)
      end
    end

    # Get an inspection of the client as a string.
    #
    # @example Inspect the client.
    #   client.inspect
    #
    # @return [ String ] The inspection string.
    #
    # @since 2.0.0
    def inspect
      "<Mongo::Client:0x#{object_id} cluster=#{cluster.addresses.join(', ')}>"
    end

    # Get the read preference from the options passed to the client.
    #
    # @example Get the read preference.
    #   client.read_preference
    #
    # @return [ Object ] The appropriate read preference or primary if none
    #   was provided to the client.
    #
    # @since 2.0.0
    def read_preference
      @read_preference ||= ServerSelector.get(options[:read] || {}, options)
    end

    # Use the database with the provided name. This will switch the current
    # database the client is operating on.
    #
    # @example Use the provided database.
    #   client.use(:users)
    #
    # @param [ String, Symbol ] name The name of the database to use.
    #
    # @return [ Mongo::Client ] The new client with new database.
    #
    # @since 2.0.0
    def use(name)
      with(database: name)
    end

    # Provides a new client with the passed options merged over the existing
    # options of this client. Useful for one-offs to change specific options
    # without altering the original client.
    #
    # @example Get a client with changed options.
    #   client.with(:read => { :mode => :primary_preferred })
    #
    # @param [ Hash ] new_options The new options to use.
    #
    # @return [ Mongo::Client ] A new client instance.
    #
    # @since 2.0.0
    def with(new_options = {})
      clone.tap do |client|
        client.options.update(new_options)
        Database.create(client)
        # We can't use the same cluster if authentication details have changed.
        if new_options[:user] || new_options[:password]
          Cluster.create(client)
        end
      end
    end

    # Get the write concern for this client. If no option was provided, then a
    # default single server acknowledgement will be used.
    #
    # @example Get the client write concern.
    #   client.write_concern
    #
    # @return [ Mongo::WriteConcern ] The write concern.
    #
    # @since 2.0.0
    def write_concern
      @write_concern ||= WriteConcern.get(options[:write])
    end

    private

    def create_from_addresses(addresses, opts = {})
      @options = Database::DEFAULT_OPTIONS.merge(opts).freeze
      @cluster = Cluster.new(addresses, options)
      @database = Database.new(self, options[:database], options)
    end

    def create_from_uri(connection_string, opts = {})
      uri = URI.new(connection_string)
      @options = Database::DEFAULT_OPTIONS.merge(uri.client_options.merge(opts)).freeze
      @cluster = Cluster.new(uri.servers, options)
      @database = Database.new(self, options[:database], options)
    end

    def initialize_copy(original)
      @options = original.options.dup
      @database = nil
      @read_preference = nil
      @write_concern = nil
    end
  end
end
