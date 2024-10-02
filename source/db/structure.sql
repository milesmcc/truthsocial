SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: api; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA api;


--
-- Name: cache; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA cache;


--
-- Name: chat_events; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA chat_events;


--
-- Name: chats; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA chats;


--
-- Name: common_logic; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA common_logic;


--
-- Name: configuration; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA configuration;


--
-- Name: cron; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA cron;


--
-- Name: database; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA database;


--
-- Name: devices; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA devices;


--
-- Name: elwood_api; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA elwood_api;


--
-- Name: extension_pg_trgm; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA extension_pg_trgm;


--
-- Name: feeds; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA feeds;


--
-- Name: geography; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA geography;


--
-- Name: logs; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA logs;


--
-- Name: mastodon_api; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA mastodon_api;


--
-- Name: mastodon_chats_api; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA mastodon_chats_api;


--
-- Name: mastodon_chats_logic; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA mastodon_chats_logic;


--
-- Name: mastodon_logic; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA mastodon_logic;


--
-- Name: mastodon_media_api; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA mastodon_media_api;


--
-- Name: notifications; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA notifications;


--
-- Name: oauth_access_tokens; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA oauth_access_tokens;


--
-- Name: polls; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA polls;


--
-- Name: queues; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA queues;


--
-- Name: recommendations; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA recommendations;


--
-- Name: reference; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA reference;


--
-- Name: registrations; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA registrations;


--
-- Name: sevro_api; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA sevro_api;


--
-- Name: statistics; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA statistics;


--
-- Name: statuses; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA statuses;


--
-- Name: trending_groups; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA trending_groups;


--
-- Name: trending_statuses; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA trending_statuses;


--
-- Name: trending_tags; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA trending_tags;


--
-- Name: tv; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tv;


--
-- Name: users; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA users;


--
-- Name: utilities; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA utilities;


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extension_pg_trgm;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: event_type; Type: TYPE; Schema: chat_events; Owner: -
--

CREATE TYPE chat_events.event_type AS ENUM (
    'chat_created',
    'chat_message_expiration_changed',
    'chat_deleted',
    'chat_silenced',
    'chat_unsilenced',
    'member_invited',
    'member_joined',
    'member_left',
    'member_rejoined',
    'member_latest_read_message_changed',
    'message_created',
    'message_edited',
    'message_hidden',
    'message_deleted',
    'message_reactions_changed',
    'chat_avatar_changed',
    'member_avatar_changed',
    'feature_unavailable',
    'subscriber_left',
    'subscriber_rejoined'
);


--
-- Name: chat_type; Type: TYPE; Schema: chats; Owner: -
--

CREATE TYPE chats.chat_type AS ENUM (
    'direct',
    'channel'
);


--
-- Name: message_modification_type; Type: TYPE; Schema: chats; Owner: -
--

CREATE TYPE chats.message_modification_type AS ENUM (
    'delete_own',
    'delete_other',
    'undelete',
    'hide',
    'unhide',
    'edit'
);


--
-- Name: message_type; Type: TYPE; Schema: chats; Owner: -
--

CREATE TYPE chats.message_type AS ENUM (
    'text',
    'media'
);


--
-- Name: chat_event; Type: TYPE; Schema: common_logic; Owner: -
--

CREATE TYPE common_logic.chat_event AS (
	event_id bigint,
	chat_id integer,
	event_type chat_events.event_type,
	"timestamp" timestamp with time zone,
	payload jsonb
);


--
-- Name: chat_event_basic; Type: TYPE; Schema: common_logic; Owner: -
--

CREATE TYPE common_logic.chat_event_basic AS (
	event_id bigint,
	chat_id integer,
	event_type chat_events.event_type,
	"timestamp" timestamp with time zone
);


--
-- Name: paginated_json; Type: TYPE; Schema: common_logic; Owner: -
--

CREATE TYPE common_logic.paginated_json AS (
	json jsonb,
	page_maximum_id bigint,
	last_page boolean
);


--
-- Name: feature_flag_status; Type: TYPE; Schema: configuration; Owner: -
--

CREATE TYPE configuration.feature_flag_status AS ENUM (
    'enabled',
    'disabled',
    'account_based'
);


--
-- Name: value_type; Type: TYPE; Schema: configuration; Owner: -
--

CREATE TYPE configuration.value_type AS ENUM (
    'integer',
    'interval',
    'double precision',
    'boolean'
);


--
-- Name: index; Type: TYPE; Schema: database; Owner: -
--

CREATE TYPE database.index AS (
	index_id oid,
	schema text,
	"table" text,
	index text,
	access_method text,
	definition text[],
	"unique" boolean,
	partial_predicate text,
	size bigint,
	scans bigint,
	last_scan timestamp with time zone,
	comment text
);


--
-- Name: configuration; Type: TYPE; Schema: elwood_api; Owner: -
--

CREATE TYPE elwood_api.configuration AS (
	notification_channel text,
	callback_sql text,
	sleep_after_callback interval
);


--
-- Name: feed_type; Type: TYPE; Schema: feeds; Owner: -
--

CREATE TYPE feeds.feed_type AS ENUM (
    'following',
    'for_you',
    'groups',
    'custom'
);


--
-- Name: visibility_type; Type: TYPE; Schema: feeds; Owner: -
--

CREATE TYPE feeds.visibility_type AS ENUM (
    'public',
    'private'
);


--
-- Name: account_deletion_type; Type: TYPE; Schema: logs; Owner: -
--

CREATE TYPE logs.account_deletion_type AS ENUM (
    'account_batch_reject',
    'activitypub_delete_person',
    'admin_reject',
    'api_admin_reject',
    'mastodon_cli_create',
    'mastodon_cli_cull',
    'mastodon_cli_delete',
    'mastodon_cli_purge',
    'self_deletion',
    'service_account_merging',
    'service_block_domain',
    'service_unallowed_domain',
    'service_user_cleanup',
    'unknown',
    'worker_admin_account_deletion'
);


--
-- Name: ids_and_total_results; Type: TYPE; Schema: mastodon_api; Owner: -
--

CREATE TYPE mastodon_api.ids_and_total_results AS (
	ids bigint[],
	total_results bigint
);


--
-- Name: json_and_total_results; Type: TYPE; Schema: mastodon_api; Owner: -
--

CREATE TYPE mastodon_api.json_and_total_results AS (
	json jsonb,
	total_results bigint
);


--
-- Name: account_avatar; Type: TYPE; Schema: mastodon_logic; Owner: -
--

CREATE TYPE mastodon_logic.account_avatar AS (
	id text,
	username text,
	acct text,
	url text,
	avatar text,
	avatar_static text,
	display_name text,
	verified boolean
);


--
-- Name: chat_avatar_change_payload; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.chat_avatar_change_payload AS (
	avatar mastodon_logic.account_avatar
);


--
-- Name: chat_creation_payload; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.chat_creation_payload AS (
	owner_account_id text,
	message_expiration integer,
	chat jsonb,
	avatar mastodon_logic.account_avatar,
	silenced boolean
);


--
-- Name: chat_creation_payload_chat_channel; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.chat_creation_payload_chat_channel AS (
	chat_type chats.chat_type,
	subscribers integer
);


--
-- Name: chat_creation_payload_chat_direct; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.chat_creation_payload_chat_direct AS (
	chat_type chats.chat_type
);


--
-- Name: chat_message_expiration_change_payload; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.chat_message_expiration_change_payload AS (
	message_expiration integer,
	changed_by_account_id text
);


--
-- Name: chat_message_search_result; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.chat_message_search_result AS (
	account mastodon_logic.account_avatar,
	message_id text,
	chat_id text,
	matches text
);


--
-- Name: detailed_emoji_reaction; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.detailed_emoji_reaction AS (
	name text,
	count integer,
	me boolean,
	avatars mastodon_logic.account_avatar[]
);


--
-- Name: emoji_reaction; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.emoji_reaction AS (
	name text,
	count integer,
	me boolean
);


--
-- Name: event; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.event AS (
	event_id bigint,
	chat_id integer,
	event_type chat_events.event_type,
	"timestamp" text,
	payload jsonb
);


--
-- Name: event_basic; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.event_basic AS (
	event_id bigint,
	chat_id integer,
	event_type chat_events.event_type,
	"timestamp" timestamp with time zone
);


--
-- Name: media_attachment; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.media_attachment AS (
	id text,
	type text,
	url text,
	preview_url text,
	external_video_id text,
	remote_url text,
	preview_remote_url text,
	text_url text,
	meta jsonb,
	description text,
	blurhash text
);


--
-- Name: member_avatar_change_payload; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.member_avatar_change_payload AS (
	account_id text,
	avatar mastodon_logic.account_avatar
);


--
-- Name: member_invitation_payload; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.member_invitation_payload AS (
	invited_account_id text,
	invited_by_account_id text
);


--
-- Name: member_join_payload; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.member_join_payload AS (
	account_id text,
	avatar mastodon_logic.account_avatar
);


--
-- Name: member_latest_read_message_change_payload; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.member_latest_read_message_change_payload AS (
	account_id text,
	latest_read_message_created_at text
);


--
-- Name: member_leave_payload; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.member_leave_payload AS (
	account_id text
);


--
-- Name: member_rejoin_payload; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.member_rejoin_payload AS (
	account_id text,
	avatar mastodon_logic.account_avatar,
	chat_details mastodon_chats_logic.chat_creation_payload
);


--
-- Name: message; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.message AS (
	id text,
	chat_id text,
	account_id text,
	message_type chats.message_type,
	content text,
	created_at text,
	unread boolean,
	expiration integer,
	emoji_reactions mastodon_chats_logic.emoji_reaction[],
	media_attachments mastodon_chats_logic.media_attachment[],
	idempotency_key text
);


--
-- Name: message_creation_payload; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.message_creation_payload AS (
	message_id text,
	created_by_account_id text,
	idempotency_key text,
	expiration integer,
	emoji_reactions mastodon_chats_logic.emoji_reaction[],
	hidden boolean,
	unread boolean,
	message jsonb
);


--
-- Name: message_creation_payload_message_media; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.message_creation_payload_message_media AS (
	message_type chats.message_type,
	content text,
	media_attachments mastodon_chats_logic.media_attachment[]
);


--
-- Name: message_creation_payload_message_text; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.message_creation_payload_message_text AS (
	message_type chats.message_type,
	content text
);


--
-- Name: message_deletion_payload; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.message_deletion_payload AS (
	message_id text
);


--
-- Name: message_for_janus; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.message_for_janus AS (
	id bigint,
	message_type chats.message_type,
	account_id bigint,
	chat_id integer,
	content text,
	created_at text,
	expiration integer,
	media_attachments mastodon_chats_logic.media_attachment[]
);


--
-- Name: message_hidden_payload; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.message_hidden_payload AS (
	message_id text,
	account_id text
);


--
-- Name: message_reactions_change_payload; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.message_reactions_change_payload AS (
	message_id text,
	emoji_reactions mastodon_chats_logic.emoji_reaction[]
);


--
-- Name: message_with_context; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.message_with_context AS (
	message mastodon_chats_logic.message_for_janus,
	before mastodon_chats_logic.message_for_janus[],
	after mastodon_chats_logic.message_for_janus[]
);


--
-- Name: subscriber_leave_payload; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.subscriber_leave_payload AS (
	account_id text
);


--
-- Name: subscriber_rejoin_payload; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.subscriber_rejoin_payload AS (
	account_id text,
	chat_details mastodon_chats_logic.chat_creation_payload
);


--
-- Name: undisplayable_event_payload; Type: TYPE; Schema: mastodon_chats_logic; Owner: -
--

CREATE TYPE mastodon_chats_logic.undisplayable_event_payload AS (
	message text,
	link text,
	link_title text
);


--
-- Name: group_owner; Type: TYPE; Schema: mastodon_logic; Owner: -
--

CREATE TYPE mastodon_logic.group_owner AS (
	id text
);


--
-- Name: group_source; Type: TYPE; Schema: mastodon_logic; Owner: -
--

CREATE TYPE mastodon_logic.group_source AS (
	note text
);


--
-- Name: tag_simple; Type: TYPE; Schema: mastodon_logic; Owner: -
--

CREATE TYPE mastodon_logic.tag_simple AS (
	name text
);


--
-- Name: group; Type: TYPE; Schema: mastodon_logic; Owner: -
--

CREATE TYPE mastodon_logic."group" AS (
	id text,
	display_name text,
	created_at text,
	owner mastodon_logic.group_owner,
	note text,
	avatar text,
	avatar_static text,
	header text,
	header_static text,
	group_visibility text,
	membership_required boolean,
	domain text,
	discoverable boolean,
	locked boolean,
	members_count integer,
	tags mastodon_logic.tag_simple[],
	slug text,
	url text,
	deleted_at text,
	source mastodon_logic.group_source
);


--
-- Name: group_tag; Type: TYPE; Schema: mastodon_logic; Owner: -
--

CREATE TYPE mastodon_logic.group_tag AS (
	id text,
	name text,
	url text,
	pinned boolean,
	visible boolean,
	uses integer,
	accounts integer
);


--
-- Name: poll_option; Type: TYPE; Schema: mastodon_logic; Owner: -
--

CREATE TYPE mastodon_logic.poll_option AS (
	title text,
	votes_count integer
);


--
-- Name: poll; Type: TYPE; Schema: mastodon_logic; Owner: -
--

CREATE TYPE mastodon_logic.poll AS (
	id text,
	expires_at text,
	expired boolean,
	multiple boolean,
	votes_count integer,
	voters_count integer,
	voted boolean,
	own_votes smallint[],
	options mastodon_logic.poll_option[]
);


--
-- Name: popular_group_tag; Type: TYPE; Schema: mastodon_logic; Owner: -
--

CREATE TYPE mastodon_logic.popular_group_tag AS (
	id text,
	name text,
	url text,
	groups integer
);


--
-- Name: status_id_and_poll_json; Type: TYPE; Schema: mastodon_logic; Owner: -
--

CREATE TYPE mastodon_logic.status_id_and_poll_json AS (
	status_id bigint,
	poll_json jsonb
);


--
-- Name: status_reply_sort_order; Type: TYPE; Schema: mastodon_logic; Owner: -
--

CREATE TYPE mastodon_logic.status_reply_sort_order AS ENUM (
    'newest',
    'oldest',
    'trending',
    'controversial'
);


--
-- Name: status_top_level_reply; Type: TYPE; Schema: mastodon_logic; Owner: -
--

CREATE TYPE mastodon_logic.status_top_level_reply AS (
	status_id bigint,
	sort_order integer
);


--
-- Name: tag_history; Type: TYPE; Schema: mastodon_logic; Owner: -
--

CREATE TYPE mastodon_logic.tag_history AS (
	days_ago smallint,
	day text,
	uses text,
	accounts text
);


--
-- Name: tag_statistics; Type: TYPE; Schema: mastodon_logic; Owner: -
--

CREATE TYPE mastodon_logic.tag_statistics AS (
	name text,
	url text,
	history mastodon_logic.tag_history[],
	recent_statuses_count integer,
	recent_history integer[]
);


--
-- Name: media_attachment; Type: TYPE; Schema: mastodon_media_api; Owner: -
--

CREATE TYPE mastodon_media_api.media_attachment AS (
	id bigint,
	status_id bigint,
	file_file_name text,
	file_content_type text,
	file_file_size integer,
	file_updated_at timestamp without time zone,
	remote_url text,
	created_at timestamp without time zone,
	updated_at timestamp without time zone,
	shortcode text,
	type integer,
	file_meta json,
	account_id bigint,
	description text,
	scheduled_status_id bigint,
	blurhash text,
	processing integer,
	file_storage_schema_version integer,
	thumbnail_file_name text,
	thumbnail_content_type text,
	thumbnail_file_size integer,
	thumbnail_updated_at timestamp without time zone,
	thumbnail_remote_url text,
	external_video_id text,
	file_s3_host text
);


--
-- Name: challenge_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.challenge_type AS ENUM (
    'attestation',
    'assertion',
    'integrity'
);


--
-- Name: group_membership_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.group_membership_role AS ENUM (
    'owner',
    'admin',
    'user'
);


--
-- Name: group_statuses_visibility; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.group_statuses_visibility AS ENUM (
    'everyone',
    'members_only'
);


--
-- Name: group_tag_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.group_tag_type AS ENUM (
    'pinned',
    'normal',
    'hidden'
);


--
-- Name: image_content_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.image_content_type AS ENUM (
    'image/gif',
    'image/jpeg',
    'image/png'
);


--
-- Name: link_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.link_status AS ENUM (
    'normal',
    'warning',
    'blocked',
    'review',
    'whitelisted',
    'spam'
);


--
-- Name: status_pin_location; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.status_pin_location AS ENUM (
    'profile',
    'group'
);


--
-- Name: distribution_type; Type: TYPE; Schema: queues; Owner: -
--

CREATE TYPE queues.distribution_type AS ENUM (
    'author',
    'followers'
);


--
-- Name: moderation_result; Type: TYPE; Schema: statuses; Owner: -
--

CREATE TYPE statuses.moderation_result AS ENUM (
    'ok',
    'sensitize',
    'delete',
    'review'
);


--
-- Name: trending_group_score; Type: TYPE; Schema: trending_groups; Owner: -
--

CREATE TYPE trending_groups.trending_group_score AS (
	group_id bigint,
	score double precision
);


--
-- Name: trending_tag_score; Type: TYPE; Schema: trending_tags; Owner: -
--

CREATE TYPE trending_tags.trending_tag_score AS (
	tag_id bigint,
	score integer
);


--
-- Name: cleanup_trending_status_excluded_statuses(); Type: PROCEDURE; Schema: api; Owner: -
--

CREATE PROCEDURE api.cleanup_trending_status_excluded_statuses()
    LANGUAGE sql
    AS $$
delete from		"trending_statuses"."excluded_statuses" "e"
	where		exists (
				select			1
					from		"public"."statuses" "s"
					where		"s"."id" = "e"."status_id"
						and	"s"."created_at" < (
								current_timestamp
							-	"configuration"."feature_setting_value" (
									'trending_statuses',
									'status_created_interval'
								)::interval
							)
			)
$$;


--
-- Name: send_refresh_group_tag_use_cache_notification(); Type: FUNCTION; Schema: cache; Owner: -
--

CREATE FUNCTION cache.send_refresh_group_tag_use_cache_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	notify "refresh_group_tag_use_cache";
	return null;
end
$$;


--
-- Name: send_refresh_tag_use_cache_notification(); Type: FUNCTION; Schema: cache; Owner: -
--

CREATE FUNCTION cache.send_refresh_tag_use_cache_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	notify "refresh_tag_use_cache";
	return null;
end
$$;


--
-- Name: update_group_status_tags_after_statuses_tags_insert(); Type: FUNCTION; Schema: cache; Owner: -
--

CREATE FUNCTION cache.update_group_status_tags_after_statuses_tags_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"cache"."group_status_tags" (
					"status_id",
					"tag_id",
					"group_id",
					"account_id",
					"created_at"
				)
	select			"n"."status_id",
				"n"."tag_id",
				"s"."group_id",
				"s"."account_id",
				"s"."created_at" at time zone 'UTC'
		from		"new_data" "n"
		join		"public"."statuses" "s"
			on	"s"."id" = "n"."status_id"
		where		"s"."deleted_at" is null
			and	"s"."visibility" = 6;
	return null;
end
$$;


--
-- Name: update_group_status_tags_after_statuses_update(); Type: FUNCTION; Schema: cache; Owner: -
--

CREATE FUNCTION cache.update_group_status_tags_after_statuses_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"cache"."group_status_tags" (
					"status_id",
					"tag_id",
					"group_id",
					"account_id",
					"created_at"
				)
	select			"t"."status_id",
				"t"."tag_id",
				"n"."group_id",
				"n"."account_id",
				"n"."created_at" at time zone 'UTC'
		from		"new_data" "n"
		join		"old_data" "o"
			using	("id")
		join		"public"."statuses_tags" "t"
			on	"t"."status_id" = "n"."id"
		where		(
					"n"."visibility" = 6
				and	"n"."deleted_at" is null
				and	(
						"o"."visibility" <> 6
					or	"o"."deleted_at" is not null
					)
				);
	delete from		"cache"."group_status_tags" "c"
		using		"old_data" "o",
				"new_data" "n"
		where		"o"."id" = "n"."id"
			and	(
					"o"."visibility" = 6
				and	"o"."deleted_at" is null
				and	(
						"n"."visibility" <> 6
					or	"n"."deleted_at" is not null
					)
				)
			and	"c"."status_id" = "n"."id";
	update			"cache"."group_status_tags" "c"
		set		"created_at" = "n"."created_at" at time zone 'UTC'
		from		"new_data" "n",
				"old_data" "o"
		where		"o"."id" = "n"."id"
			and	"c"."status_id" = "n"."id"
			and	"n"."deleted_at" is null
			and	"n"."visibility" = 6;
	return null;
end
$$;


--
-- Name: update_status_tags_after_statuses_tags_insert(); Type: FUNCTION; Schema: cache; Owner: -
--

CREATE FUNCTION cache.update_status_tags_after_statuses_tags_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"cache"."status_tags" (
					"status_id",
					"tag_id",
					"account_id",
					"created_at"
				)
	select			"n"."status_id",
				"n"."tag_id",
				"s"."account_id",
				"s"."created_at" at time zone 'UTC'
		from		"new_data" "n"
		join		"public"."statuses" "s"
			on	"s"."id" = "n"."status_id"
		where		"s"."deleted_at" is null
			and	"s"."visibility" = 0;
	return null;
end
$$;


--
-- Name: update_status_tags_after_statuses_update(); Type: FUNCTION; Schema: cache; Owner: -
--

CREATE FUNCTION cache.update_status_tags_after_statuses_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"cache"."status_tags" (
					"status_id",
					"tag_id",
					"account_id",
					"created_at"
				)
	select			"t"."status_id",
				"t"."tag_id",
				"n"."account_id",
				"n"."created_at" at time zone 'UTC'
		from		"new_data" "n"
		join		"old_data" "o"
			using	("id")
		join		"public"."statuses_tags" "t"
			on	"t"."status_id" = "n"."id"
		where		(
					"n"."visibility" = 0
				and	"n"."deleted_at" is null
				and	(
						"o"."visibility" <> 0
					or	"o"."deleted_at" is not null
					)
				);
	delete from		"cache"."status_tags" "c"
		using		"old_data" "o",
				"new_data" "n"
		where		"o"."id" = "n"."id"
			and	(
					"o"."visibility" = 0
				and	"o"."deleted_at" is null
				and	(
						"n"."visibility" <> 0
					or	"n"."deleted_at" is not null
					)
				)
			and	"c"."status_id" = "n"."id";
	update			"cache"."status_tags" "c"
		set		"created_at" = "n"."created_at" at time zone 'UTC'
		from		"new_data" "n",
				"old_data" "o"
		where		"o"."id" = "n"."id"
			and	"c"."status_id" = "n"."id"
			and	"n"."deleted_at" is null
			and	"n"."visibility" = 0;
	return null;
end
$$;


--
-- Name: keep_only_latest_chat_avatar_changed_event(); Type: FUNCTION; Schema: chat_events; Owner: -
--

CREATE FUNCTION chat_events.keep_only_latest_chat_avatar_changed_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	with "keep_events" (
		"chat_id",
		"event_id"
	) as (
		select			"chat_id",
					max ("event_id")
			from		"new_data"
			where		"event_type" = 'chat_avatar_changed'
			group by	1
	)
	delete from		"chat_events"."events" "e"
		using		"keep_events" "k"
		where		"e"."chat_id" = "k"."chat_id"
			and	"e"."event_id" <> "k"."event_id"
			and	"e"."event_type" = 'chat_avatar_changed';
	return null;
end
$$;


--
-- Name: keep_only_latest_chat_silence_event(); Type: FUNCTION; Schema: chat_events; Owner: -
--

CREATE FUNCTION chat_events.keep_only_latest_chat_silence_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	with "keep_events" (
		"chat_id",
		"account_id",
		"event_id"
	) as (
		select			"e"."chat_id",
					"n"."account_id",
					max ("e"."event_id")
			from		"new_data" "n"
			join		"chat_events"."events" "e"
				using	("event_id")
			group by	1, 2
	)
	delete from		"chat_events"."events" "e"
		using		"chat_events"."chat_silences" "s",
				"chat_events"."chat_unsilences" "u",
				"keep_events" "k"
		where		"e"."chat_id" = "k"."chat_id"
			and	(
					(
						"s"."account_id" = "k"."account_id"
					and	"e"."event_id" = "s"."event_id"
					)
				or	(
						"u"."account_id" = "k"."account_id"
					and	"e"."event_id" = "u"."event_id"
					)
				)
			and	"e"."event_id" <> "k"."event_id"
			and	"e"."event_type" in (
					'chat_silenced',
					'chat_unsilenced'
				);
	return null;
end
$$;


--
-- Name: keep_only_latest_chat_unsilence_event(); Type: FUNCTION; Schema: chat_events; Owner: -
--

CREATE FUNCTION chat_events.keep_only_latest_chat_unsilence_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	with "keep_events" (
		"chat_id",
		"account_id",
		"event_id"
	) as (
		select			"e"."chat_id",
					"n"."account_id",
					max ("e"."event_id")
			from		"new_data" "n"
			join		"chat_events"."events" "e"
				using	("event_id")
			group by	1, 2
	)
	delete from		"chat_events"."events" "e"
		using		"chat_events"."chat_silences" "s",
				"chat_events"."chat_unsilences" "u",
				"keep_events" "k"
		where		"e"."chat_id" = "k"."chat_id"
			and	(
					(
						"s"."account_id" = "k"."account_id"
					and	"e"."event_id" = "s"."event_id"
					)
				or	(
						"u"."account_id" = "k"."account_id"
					and	"e"."event_id" = "u"."event_id"
					)
				)
			and	"e"."event_id" <> "k"."event_id"
			and	"e"."event_type" in (
					'chat_silenced',
					'chat_unsilenced'
				);
	return null;
end
$$;


--
-- Name: keep_only_latest_member_avatar_changed_event(); Type: FUNCTION; Schema: chat_events; Owner: -
--

CREATE FUNCTION chat_events.keep_only_latest_member_avatar_changed_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	with "keep_events" (
		"chat_id",
		"account_id",
		"event_id"
	) as (
		select			"e"."chat_id",
					"n"."account_id",
					max ("e"."event_id")
			from		"new_data" "n"
			join		"chat_events"."events" "e"
				using	("event_id")
			group by	1, 2
	)
	delete from		"chat_events"."events" "e"
		using		"chat_events"."member_avatar_changes" "a",
				"keep_events" "k"
		where		"e"."chat_id" = "k"."chat_id"
			and	"a"."account_id" = "k"."account_id"
			and	"e"."event_id" = "a"."event_id"
			and	"e"."event_id" <> "k"."event_id"
			and	"e"."event_type" = 'member_avatar_changed';
	return null;
end
$$;


--
-- Name: keep_only_latest_member_latest_read_message_changed_event(); Type: FUNCTION; Schema: chat_events; Owner: -
--

CREATE FUNCTION chat_events.keep_only_latest_member_latest_read_message_changed_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	with "keep_events" (
		"chat_id",
		"account_id",
		"event_id"
	) as (
		select			"e"."chat_id",
					"n"."account_id",
					max ("e"."event_id")
			from		"new_data" "n"
			join		"chat_events"."events" "e"
				using	("event_id")
			group by	1, 2
	)
	delete from		"chat_events"."events" "e"
		using		"chat_events"."member_latest_read_message_changes" "l",
				"keep_events" "k"
		where		"e"."chat_id" = "k"."chat_id"
			and	"l"."account_id" = "k"."account_id"
			and	"e"."event_id" = "l"."event_id"
			and	"e"."event_id" <> "k"."event_id"
			and	"e"."event_type" = 'member_latest_read_message_changed';
	return null;
end
$$;


--
-- Name: keep_only_latest_message_edited_event(); Type: FUNCTION; Schema: chat_events; Owner: -
--

CREATE FUNCTION chat_events.keep_only_latest_message_edited_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	with "keep_events" (
		"message_id",
		"event_id"
	) as (
		select			"message_id",
					max ("event_id")
			from		"new_data"
			group by	1
	)
	delete from		"chat_events"."events" "e"
		using		"chat_events"."message_edits" "m",
				"keep_events" "k"
		where		"m"."message_id" = "k"."message_id"
			and	"e"."event_id" = "m"."event_id"
			and	"e"."event_id" <> "k"."event_id"
			and	"e"."event_type" = 'message_edited';
	return null;
end
$$;


--
-- Name: keep_only_latest_message_reactions_changed_event(); Type: FUNCTION; Schema: chat_events; Owner: -
--

CREATE FUNCTION chat_events.keep_only_latest_message_reactions_changed_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin

	with "keep_events" (
		"message_id",
		"event_id"
	) as (
		select			"message_id",
					max ("event_id")
			from		"new_data"
			group by	1
	)
	delete from		"chat_events"."events" "e"
		using		"chat_events"."message_reactions_changes" "c",
				"keep_events" "k"
		where		"c"."message_id" = "k"."message_id"
			and	"e"."event_id" = "c"."event_id"
			and	"e"."event_id" <> "k"."event_id"
			and	"e"."event_type" = 'message_reactions_changed';
	return null;
end
$$;


--
-- Name: keep_only_latest_subscriber_left_event(); Type: FUNCTION; Schema: chat_events; Owner: -
--

CREATE FUNCTION chat_events.keep_only_latest_subscriber_left_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	with "keep_events" (
		"chat_id",
		"account_id",
		"event_id"
	) as (
		select			"e"."chat_id",
					"n"."account_id",
					max ("e"."event_id")
			from		"new_data" "n"
			join		"chat_events"."events" "e"
				using	("event_id")
			group by	1, 2
	)
	delete from		"chat_events"."events" "e"
		using		"chat_events"."subscriber_leaves" "l",
				"keep_events" "k"
		where		"e"."chat_id" = "k"."chat_id"
			and	"l"."account_id" = "k"."account_id"
			and	"e"."event_id" = "l"."event_id"
			and	"e"."event_id" <> "k"."event_id"
			and	"e"."event_type" = 'subscriber_left';
	return null;
end
$$;


--
-- Name: keep_only_latest_subscriber_rejoined_event(); Type: FUNCTION; Schema: chat_events; Owner: -
--

CREATE FUNCTION chat_events.keep_only_latest_subscriber_rejoined_event() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	with "keep_events" (
		"chat_id",
		"account_id",
		"event_id"
	) as (
		select			"e"."chat_id",
					"n"."account_id",
					max ("e"."event_id")
			from		"new_data" "n"
			join		"chat_events"."events" "e"
				using	("event_id")
			group by	1, 2
	)
	delete from		"chat_events"."events" "e"
		using		"chat_events"."subscriber_rejoins" "l",
				"keep_events" "k"
		where		"e"."chat_id" = "k"."chat_id"
			and	"l"."account_id" = "k"."account_id"
			and	"e"."event_id" = "l"."event_id"
			and	"e"."event_id" <> "k"."event_id"
			and	"e"."event_type" = 'subscriber_rejoined';
	return null;
end
$$;


--
-- Name: archive_deleted_chats(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.archive_deleted_chats() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"chats"."deleted_chats" (
					"chat_id",
					"owner_account_id",
					"created_at",
					"message_expiration",
					"chat_type"
				)
		values		(
					"old"."chat_id",
					"old"."owner_account_id",
					"old"."created_at",
					"old"."message_expiration",
					"old"."chat_type"
				);
	return "old";
end
$$;


--
-- Name: archive_deleted_members(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.archive_deleted_members() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"chats"."deleted_members" (
					"chat_id",
					"account_id",
					"accepted",
					"active",
					"oldest_visible_at",
					"latest_read_message_created_at",
					"silenced"
				)
		values		(
					"old"."chat_id",
					"old"."account_id",
					"old"."accepted",
					"old"."active",
					"old"."oldest_visible_at",
					"old"."latest_read_message_created_at",
					"old"."silenced"
				)
		on conflict	(
					"chat_id",
					"account_id"
				)
			do	nothing;
	return "old";
end
$$;


--
-- Name: archive_deleted_message_text(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.archive_deleted_message_text() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"chats"."deleted_message_text" (
					"message_id",
					"content"
				)
		values		(
					"old"."message_id",
					"old"."content"
				);
	return "old";
end
$$;


--
-- Name: archive_deleted_messages(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.archive_deleted_messages() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"chats"."deleted_messages" (
					"message_id",
					"chat_id",
					"message_type",
					"created_at",
					"expiration",
					"created_by_account_id"
				)
		values		(
					"old"."message_id",
					"old"."chat_id",
					"old"."message_type",
					"old"."created_at",
					"old"."expiration",
					"old"."created_by_account_id"
				);
	return "old";
end
$$;


--
-- Name: chat_create_from_api_view(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.chat_create_from_api_view() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
	"var_account"		bigint;
	"var_chat_id"		bigint;
	"var_members"		bigint[];
begin
	if "new"."chat_id" is not null then
		raise exception 'Attempted to set "chat_id" when inserting to "api"."chats".  This is not possible!';
	elsif "new"."created_at" is not null then
		raise exception 'Attempted to set "created_at" when inserting to "api"."chats".  This is not possible!';
	end if;
	if "new"."chat_type" = 'direct' then
		"var_members" := "utilities"."array_sort" (
			"utilities"."array_subtract" ("new"."members", array["new"."owner_account_id"])
		||	array["new"."owner_account_id"]
		);
		select			"chat_id"
			into		"var_chat_id"
			from		"chats"."member_lists"
			where		"members" = "var_members"
			limit		1;
		if found then
			raise exception 'Cannot create a new direct message chat between accounts % and %, as this would be a duplicate of chat ID %!',
				"var_members"[1],
				"var_members"[2],
				"var_chat_id";
		end if;
	end if;
	insert into		"chats"."chats" (
					"owner_account_id",
					"message_expiration"
				)
		values		(
					"new"."owner_account_id",
					"new"."message_expiration"
				)
		returning	"chat_id",
				"created_at"
			into	"new"."chat_id",
				"new"."created_at";
	insert into		"chats"."members" (
					"chat_id",
					"account_id",
					"accepted"
				)
		values		(
					"new"."chat_id",
					"new"."owner_account_id",
					true
				);
	foreach "var_account" in array "utilities"."array_subtract" ("new"."members", array["new"."owner_account_id"]) loop
		insert into		"chats"."members" (
						"chat_id",
						"account_id"
					)
			values		(
						"new"."chat_id",
						"var_account"
					);
	end loop;
	return "new";
end
$$;


--
-- Name: chat_delete_from_api_view(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.chat_delete_from_api_view() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	delete from		"chats"."chats"
		where		"chat_id" = "old"."chat_id";
	return "old";
end
$$;


--
-- Name: chat_member_create_from_api_view(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.chat_member_create_from_api_view() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if "new"."unread_messages_count" is not null then
		raise exception 'Attempted to set "unread_messages_count" when inserting to "api"."chat_members".  This is not possible!';
	elsif "new"."other_member_account_ids" is not null then
		raise exception 'Attempted to set "other_member_account_ids" when inserting to "api"."chat_members".  This is not possible!';
	elsif "new"."latest_message_at" is not null then
		raise exception 'Attempted to set "latest_message_at" when inserting to "api"."chat_members".  This is not possible!';
	elsif "new"."latest_message_id" is not null then
		raise exception 'Attempted to set "latest_message_id" when inserting to "api"."chat_members".  This is not possible!';
	elsif "new"."latest_activity_at" is not null then
		raise exception 'Attempted to set "latest_activity_at" when inserting to "api"."chat_members".  This is not possible!';
	elsif "new"."blocked" is not null then
		raise exception 'Attempted to set "blocked" when inserting to "api"."chat_members".  This is not possible!';
	end if;
	insert into		"chats"."members" (
					"chat_id",
					"account_id",
					"accepted",
					"active",
					"latest_read_message_created_at",
					"silenced"
				)
		values		(
					"new"."chat_id",
					"new"."account_id",
					"new"."accepted",
					"new"."active",
					"new"."latest_read_message_created_at",
					"new"."silenced"
				);
	return "new";
end
$$;


--
-- Name: chat_member_delete_from_api_view(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.chat_member_delete_from_api_view() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	delete from		"chats"."members"
		where		"chat_id" = "old"."chat_id"
			and	"account_id" = "old"."account_id";
	return "old";
end
$$;


--
-- Name: chat_member_update_from_api_view(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.chat_member_update_from_api_view() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if "old"."chat_id" is distinct from "new"."chat_id" then
		raise exception 'Attempted to modify "chat_id" when updating "api"."chat_members".  This is not possible!';
	elsif "old"."account_id" is distinct from "new"."account_id" then
		raise exception 'Attempted to modify "account_id" when updating "api"."chat_members".  This is not possible!';
	elsif "old"."unread_messages_count" is distinct from "new"."unread_messages_count" then
		raise exception 'Attempted to modify "unread_messages_count" when updating "api"."chat_members".  This is not possible!';
	elsif "old"."other_member_account_ids" is distinct from "new"."other_member_account_ids" then
		raise exception 'Attempted to modify "other_member_account_ids" when updating "api"."chat_members".  This is not possible!';
	elsif "old"."latest_message_at" is distinct from "new"."latest_message_at" then
		raise exception 'Attempted to modify "latest_message_at" when updating "api"."chat_members".  This is not possible!';
	elsif "old"."latest_message_id" is distinct from "new"."latest_message_id" then
		raise exception 'Attempted to modify "latest_message_id" when updating "api"."chat_members".  This is not possible!';
	elsif "old"."latest_activity_at" is distinct from "new"."latest_activity_at" then
		raise exception 'Attempted to modify "latest_activity_at" when updating "api"."chat_members".  This is not possible!';
	elsif "old"."blocked" is distinct from "new"."blocked" then
		raise exception 'Attempted to modify "blocked" when updating "api"."chat_members".  This is not possible!';
	end if;
	if (
		"new"."accepted" is distinct from "old"."accepted"
	or	"new"."active" is distinct from "old"."active"
	or	"new"."latest_read_message_created_at" is distinct from "old"."latest_read_message_created_at"
	or	"new"."silenced" is distinct from "old"."silenced"
	) then
		update			"chats"."members"
			set		"accepted" = "new"."accepted",
					"active" = "new"."active",
					"latest_read_message_created_at" = "new"."latest_read_message_created_at",
					"silenced" = "new"."silenced"
			where		"chat_id" = "new"."chat_id"
				and	"account_id" = "new"."account_id";
	end if;
	return "new";
end
$$;


--
-- Name: chat_owner_account_id(integer); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.chat_owner_account_id(in_chat_id integer) RETURNS bigint
    LANGUAGE sql STABLE
    AS $$
select			"owner_account_id"
	from		"chats"."chats"
	where		"chat_id" = "in_chat_id";
$$;


--
-- Name: chat_type(integer); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.chat_type(in_chat_id integer) RETURNS chats.chat_type
    LANGUAGE sql STABLE
    AS $$
select			"chat_type"
	from		"chats"."chats"
	where		"chat_id" = "in_chat_id"
$$;


--
-- Name: chat_update_from_api_view(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.chat_update_from_api_view() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
	"var_account"		bigint;
begin
	if "old"."chat_id" is distinct from "new"."chat_id" then
		raise exception 'Attempted to modify "chat_id" when updating "api"."chats".  This is not possible!';
	elsif "old"."created_at" is distinct from "new"."created_at" then
		raise exception 'Attempted to modify "created_at" when updating "api"."chats".  This is not possible!';
	elsif "old"."owner_account_id" is distinct from "new"."owner_account_id" then
		raise exception 'Attempted to modify "owner_account_id" when updating "api"."chats".  This is not possible!';
	end if;
	if (
		"new"."message_expiration" is distinct from "old"."message_expiration"
	or	"new"."owner_account_id" is distinct from "old"."owner_account_id"
	) then
		update			"chats"."chats"
			set		"message_expiration" = "new"."message_expiration",
					"owner_account_id" = "new"."owner_account_id"
			where		"chat_id" = "new"."chat_id";
		if "new"."message_expiration" is distinct from "old"."message_expiration" then
			insert into		"chats"."chat_message_expiration_changes" (
							"chat_id",
							"message_expiration"
						)
				values		(
							"new"."chat_id",
							"new"."message_expiration"
						);
		end if;
	end if;
	if "old"."members" is distinct from "new"."members" then
		foreach "var_account" in array "utilities"."array_subtract" ("old"."members", "new"."members") loop
			if "var_account" = "new"."owner_account_id" then
				raise exception 'Current owner of the chat cannot be removed!';
			end if;
			delete from		"chats"."members"
				where		"chat_id" = "new"."chat_id"
					and	"account_id" = "var_account";
		end loop;
		foreach "var_account" in array "utilities"."array_subtract" ("new"."members", "old"."members") loop
			insert into		"chats"."members" (
							"chat_id",
							"account_id"
						)
				values		(
							"new"."chat_id",
							"var_account"
						);
		end loop;
	end if;
	return "new";
end
$$;


--
-- Name: create_chat_avatar_change_events(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.create_chat_avatar_change_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_events" (
					"chat_id",
					"event_type"
				)
	select			"c"."chat_id",
				'chat_avatar_changed'
		from		"new_data" "n"
		join		"old_data" "o"
			using	("id")
		join		"chats"."chats" "c"
			on	"c"."owner_account_id" = "n"."id"
		where		"c"."chat_type" = 'channel'
			and	(
					"o"."username" <> "n"."username"
				or	"o"."avatar_file_name" is distinct from "n"."avatar_file_name"
				or	"o"."display_name" <> "n"."display_name"
				or	"o"."verified" <> "n"."verified"
				);
	return null;
end
$$;


--
-- Name: create_chat_creation_events(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.create_chat_creation_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_events" (
					"chat_id",
					"event_type"
				)
	select			"chat_id",
				'chat_created'
		from		"new_data";
	return null;
end
$$;


--
-- Name: create_chat_deletion_events(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.create_chat_deletion_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_events" (
					"chat_id",
					"event_type"
				)
	select			"chat_id",
				'chat_deleted'
		from		"old_data";
	return null;
end
$$;


--
-- Name: create_chat_message_expiration_change_events(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.create_chat_message_expiration_change_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_events" (
					"chat_id",
					"event_type",
					"payload"
				)
	select			"chat_id",
				'chat_message_expiration_changed',
				"jsonb_build_object" (
					'message_expiration',		extract ('epoch' from "message_expiration")::int4,
					'changed_by_account_id',	"changed_by_account_id"
				)
		from		"new_data";
	return null;
end
$$;


--
-- Name: create_chat_silenced_events(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.create_chat_silenced_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_events" (
					"chat_id",
					"event_type",
					"payload"
				)
	select			"n"."chat_id",
				'chat_silenced',
				"jsonb_build_object" (
					'account_id',			"n"."account_id"
				)
		from		"new_data" "n"
		join		"old_data" "o"
			using	(
					"chat_id",
					"account_id"
				)
		where		not "o"."silenced"
			and	"n"."silenced";
	return null;
end
$$;


--
-- Name: create_chat_unsilenced_events(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.create_chat_unsilenced_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_events" (
					"chat_id",
					"event_type",
					"payload"
				)
	select			"n"."chat_id",
				'chat_unsilenced',
				"jsonb_build_object" (
					'account_id',			"n"."account_id"
				)
		from		"new_data" "n"
		join		"old_data" "o"
			using	(
					"chat_id",
					"account_id"
				)
		where		"o"."silenced"
			and	not "n"."silenced";
	return null;
end
$$;


--
-- Name: create_member_avatar_change_events(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.create_member_avatar_change_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_events" (
					"chat_id",
					"event_type",
					"payload"
				)
	select			"c"."chat_id",
				'member_avatar_changed',
				"jsonb_build_object" (
					'account_id',		"n"."id"
				)
		from		"new_data" "n"
		join		"old_data" "o"
			using	("id")
		join		"chats"."members" "b"
			on	"b"."account_id" = "n"."id"
		join		"chats"."chats" "c"
			using	("chat_id")
		where		"c"."chat_type" <> 'channel'
			and	(
					"o"."username" <> "n"."username"
				or	"o"."avatar_file_name" is distinct from "n"."avatar_file_name"
				or	"o"."display_name" <> "n"."display_name"
				or	"o"."verified" <> "n"."verified"
				);
	return null;
end
$$;


--
-- Name: create_member_invited_events(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.create_member_invited_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_events" (
					"chat_id",
					"event_type",
					"payload"
				)
	select			"n"."chat_id",
				'member_invited',
				"jsonb_build_object" (
					'invited_account_id',		"n"."account_id",
					'invited_by_account_id',	"c"."owner_account_id"
				)
		from		"new_data" "n"
		join		"chats"."chats" "c"
			using	("chat_id")
		where		"c"."chat_type" <> 'channel'
			and	"n"."account_id" <> "c"."owner_account_id";
	return null;
end
$$;


--
-- Name: create_member_joined_events(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.create_member_joined_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_events" (
					"chat_id",
					"event_type",
					"payload"
				)
	select			"n"."chat_id",
				'member_joined',
				"jsonb_build_object" (
					'account_id',			"n"."account_id"
				)
		from		"new_data" "n"
		join		"old_data" "o"
			using	(
					"chat_id",
					"account_id"
				)
		join		"chats"."chats" "c"
			using	("chat_id")
		where		"c"."chat_type" <> 'channel'
			and	not "o"."accepted"
			and	"n"."accepted";
	return null;
end
$$;


--
-- Name: create_member_latest_read_message_changed_events(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.create_member_latest_read_message_changed_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_events" (
					"chat_id",
					"event_type",
					"payload"
				)
	select			"n"."chat_id",
				'member_latest_read_message_changed',
				"jsonb_build_object" (
					'account_id',			"n"."account_id"
				)
		from		"new_data" "n"
		join		"old_data" "o"
			using	(
					"chat_id",
					"account_id"
				)
		where		"o"."latest_read_message_created_at" <> "n"."latest_read_message_created_at"
			and	not exists (
					select			1
						from		"chats"."chats"
						where		"chat_type" = 'channel'
							and	"chat_id" = "n"."chat_id"
				);
	return null;
end
$$;


--
-- Name: create_member_left_events(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.create_member_left_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_events" (
					"chat_id",
					"event_type",
					"payload"
				)
	select			"n"."chat_id",
				'member_left',
				"jsonb_build_object" (
					'account_id',			"n"."account_id"
				)
		from		"new_data" "n"
		join		"old_data" "o"
			using	(
					"chat_id",
					"account_id"
				)
		join		"chats"."chats" "c"
			using	("chat_id")
		where		"c"."chat_type" <> 'channel'
			and	"o"."active"
			and	not "n"."active";
	return null;
end
$$;


--
-- Name: create_member_rejoined_events(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.create_member_rejoined_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_events" (
					"chat_id",
					"event_type",
					"payload"
				)
	select			"n"."chat_id",
				'member_rejoined',
				"jsonb_build_object" (
					'account_id',		"n"."account_id"
				)
		from		"new_data" "n"
		join		"old_data" "o"
			using	(
					"chat_id",
					"account_id"
				)
		join		"chats"."chats" "c"
			using	("chat_id")
		where		"c"."chat_type" <> 'channel'
			and	not "o"."active"
			and	"n"."active";
	return null;
end
$$;


--
-- Name: create_message_creation_events(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.create_message_creation_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_events" (
					"chat_id",
					"event_type",
					"payload"
				)
	select			"chat_id",
				'message_created',
				"jsonb_build_object" (
					'message_id',		"message_id"
				)
		from		"new_data";
	return null;
end
$$;


--
-- Name: create_message_deletion_events(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.create_message_deletion_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_events" (
					"chat_id",
					"event_type",
					"payload"
				)
	select			"chat_id",
				'message_deleted',
				"jsonb_build_object" (
					'message_id',		"message_id"
				)
		from		"old_data";
	return null;
end
$$;


--
-- Name: create_message_edit_events(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.create_message_edit_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_events" (
					"chat_id",
					"event_type",
					"payload"
				)
	select			"m"."chat_id",
				'message_edited',
				"jsonb_build_object" (
					'message_id',		"m"."message_id"
				)
		from		"new_data" "n"
		join		"old_data" "o"
			using	("id")
		join		"chats"."message_media_attachments" "x"
			on	"x"."media_attachment_id" = "n"."id"
		join		"chats"."messages" "m"
			using	("message_id")
		where		"o"."external_video_id" is distinct from "n"."external_video_id";
	return null;
end
$$;


--
-- Name: create_message_hidden_events(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.create_message_hidden_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_events" (
					"chat_id",
					"event_type",
					"payload"
				)
	select			"m"."chat_id",
				'message_hidden',
				"jsonb_build_object" (
					'message_id',		"n"."message_id",
					'account_id',		"n"."account_id"
				)
		from		"new_data" "n"
		join		"chats"."messages" "m"
			using	("message_id");
	return null;
end
$$;


--
-- Name: create_message_reactions_changed_events_after_delete(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.create_message_reactions_changed_events_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_events" (
					"chat_id",
					"event_type",
					"payload"
				)
	select			"m"."chat_id",
				'message_reactions_changed',
				"jsonb_build_object" (
					'message_id',		"o"."message_id"
				)
		from		"old_data" "o"
		join		"chats"."messages" "m"
			using	("message_id");
	return null;
end
$$;


--
-- Name: create_message_reactions_changed_events_after_insert(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.create_message_reactions_changed_events_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_events" (
					"chat_id",
					"event_type",
					"payload"
				)
	select			"m"."chat_id",
				'message_reactions_changed',
				"jsonb_build_object" (
					'message_id',		"n"."message_id"
				)
		from		"new_data" "n"
		join		"chats"."messages" "m"
			using	("message_id");
	return null;
end
$$;


--
-- Name: create_subscriber_left_events(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.create_subscriber_left_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_events" (
					"chat_id",
					"event_type",
					"payload"
				)
	select			"n"."chat_id",
				'subscriber_left',
				"jsonb_build_object" (
					'account_id',			"n"."account_id"
				)
		from		"new_data" "n"
		join		"old_data" "o"
			using	(
					"chat_id",
					"account_id"
				)
		join		"chats"."chats" "c"
			using	("chat_id")
		where		"c"."chat_type" = 'channel'
			and	"o"."active"
			and	not "n"."active";
	return null;
end
$$;


--
-- Name: create_subscriber_rejoined_events(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.create_subscriber_rejoined_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_events" (
					"chat_id",
					"event_type",
					"payload"
				)
	select			"n"."chat_id",
				'subscriber_rejoined',
				"jsonb_build_object" (
					'account_id',			"n"."account_id"
				)
		from		"new_data" "n"
		join		"old_data" "o"
			using	(
					"chat_id",
					"account_id"
				)
		join		"chats"."chats" "c"
			using	("chat_id")
		where		"c"."chat_type" = 'channel'
			and	not "o"."active"
			and	"n"."active";
	return null;
end
$$;


--
-- Name: delete_chat_when_last_active_member_is_deleted(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.delete_chat_when_last_active_member_is_deleted() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
	"var_active_members"	int;
	"var_chat_id"		int;
begin
	for "var_chat_id" in (
		select distinct		"chat_id"
			from		"old_data"
	) loop
		select			count (1)
			into		"var_active_members"
			from		"chats"."members"
			where		"active"
				and	"chat_id" = "var_chat_id";
		if "var_active_members" = 0 then
			delete from		"chats"."chats"
				where		"chat_id" = "var_chat_id";
		end if;
	end loop;
	return null;
end
$$;


--
-- Name: delete_chat_when_last_member_becomes_inactive(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.delete_chat_when_last_member_becomes_inactive() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
	"var_active_members"	int;
	"var_chat_id"		int;
begin
	for "var_chat_id" in (
		select distinct		"chat_id"
			from		"new_data"
			where		not "active"
	) loop
		select			count (1)
			into		"var_active_members"
			from		"chats"."members"
			where		"active"
				and	"chat_id" = "var_chat_id";
		if "var_active_members" = 0 then
			delete from		"chats"."chats"
				where		"chat_id" = "var_chat_id";
		end if;
	end loop;
	return null;
end
$$;


--
-- Name: delete_message_creation_events(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.delete_message_creation_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	with "delete_events" (
		"event_id"
	) as (
		delete from		"chat_events"."message_creations" "c"
			using		"old_data" "o"
			where		"o"."message_id" = "c"."message_id"
			returning	"event_id"
	)
	delete from		"chat_events"."events" "e"
		using		"delete_events" "d"
		where		"d"."event_id" = "e"."event_id";
	return null;
end
$$;


--
-- Name: delete_message_edit_events(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.delete_message_edit_events() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	with "delete_events" (
		"event_id"
	) as (
		delete from		"chat_events"."message_edits" "c"
			using		"old_data" "o"
			where		"o"."message_id" = "c"."message_id"
			returning	"event_id"
	)
	delete from		"chat_events"."events" "e"
		using		"delete_events" "d"
		where		"d"."event_id" = "e"."event_id";
	return null;
end
$$;


--
-- Name: delete_message_notifications(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.delete_message_notifications() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	delete from		"public"."notifications" "n"
		using		"old_data" "o"
		where		"n"."activity_type" = 'ChatMessage'
			and	"n"."activity_id" = "o"."message_id";
	return null;
end
$$;


--
-- Name: delete_message_notifications_when_leaving_chat(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.delete_message_notifications_when_leaving_chat() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	delete from		"public"."notifications" "n"
		where		"n"."account_id" = "new"."account_id"
			and	"n"."activity_type" = 'ChatMessage'
			and	exists (
					select			1
						from		"chats"."messages" "m"
						where		"m"."chat_id" = "new"."chat_id"
							and	"m"."message_id" = "n"."activity_id"
			);
	return null;
end
$$;


--
-- Name: disallow_hidden_message_update(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.disallow_hidden_message_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	raise exception 'Updating hidden message records is not permitted!';
	return null;
end
$$;


--
-- Name: disallow_hiding_own_messages(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.disallow_hiding_own_messages() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	perform			1
		from		"new_data" "n"
		join		"chats"."messages" "m"
			on	"m"."message_id" = "n"."message_id"
			and	"m"."created_by_account_id" = "n"."account_id";
	if found then
		raise exception 'Messages cannot be hidden for the account that created them!';
	end if;
	return null;
end
$$;


--
-- Name: disallow_member_primary_key_change(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.disallow_member_primary_key_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	perform			1
		from		"old_data" "o"
		join		"new_data" "n"
			using	(
					"chat_id",
					"account_id"
				)
		where		"n"."chat_id" <> "o"."chat_id"
			or	"n"."account_id" <> "o"."account_id"
		limit		1;
	if found then
		raise exception 'Changing chat_id or account_id of members is not permitted!';
	end if;
	return null;
end
$$;


--
-- Name: latest_activity_at(integer, bigint); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.latest_activity_at(in_chat_id integer, in_account_id bigint) RETURNS timestamp without time zone
    LANGUAGE sql STABLE
    AS $$
select			coalesce (
				"chats"."latest_message_at" (
					"in_chat_id",
					"in_account_id"
				),
				"created_at"
			)
	from		"chats"."chats"
	where		"chat_id" = "in_chat_id"
$$;


--
-- Name: latest_message(integer, bigint); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.latest_message(in_chat_id integer, in_account_id bigint) RETURNS TABLE(latest_message_at timestamp without time zone, latest_message_id bigint)
    LANGUAGE sql STABLE
    AS $$
select			max ("m"."created_at"),
			max ("m"."message_id")
	from		"chats"."messages" "m"
	where		"m"."chat_id" = "in_chat_id"
		and	"chats"."message_visible_to_account" (
				"m"."message_id",
				"in_account_id"
			)
$$;


--
-- Name: latest_message_at(integer, bigint); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.latest_message_at(in_chat_id integer, in_account_id bigint) RETURNS timestamp without time zone
    LANGUAGE sql STABLE
    AS $$
select			"latest_message_at"
	from		"chats"."latest_message" (
				"in_chat_id",
				"in_account_id"
			)
$$;


--
-- Name: latest_message_id(integer, bigint); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.latest_message_id(in_chat_id integer, in_account_id bigint) RETURNS bigint
    LANGUAGE sql STABLE
    AS $$
select			"latest_message_id"
	from		"chats"."latest_message" (
				"in_chat_id",
				"in_account_id"
			)
$$;


--
-- Name: member_active(bigint, integer); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.member_active(in_account_id bigint, in_chat_id integer) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
select			"active"
	from		"chats"."members"
	where		"chat_id" = "in_chat_id"
		and	"account_id" = "in_account_id"
$$;


--
-- Name: member_latest_read_message_created_at(bigint, integer); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.member_latest_read_message_created_at(in_account_id bigint, in_chat_id integer) RETURNS timestamp without time zone
    LANGUAGE sql STABLE
    AS $$
select			"latest_read_message_created_at"
	from		"chats"."members"
	where		"chat_id" = "in_chat_id"
		and	"account_id" = "in_account_id";
$$;


--
-- Name: message_chat_id(bigint); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.message_chat_id(in_message_id bigint) RETURNS integer
    LANGUAGE sql
    AS $$
select			"chat_id"
	from		"chats"."messages"
	where		"message_id" = "in_message_id"
$$;


--
-- Name: message_expiration(integer); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.message_expiration(in_chat_id integer) RETURNS interval
    LANGUAGE sql STABLE
    AS $$
select			"message_expiration"
	from		"chats"."chats"
	where		"chat_id" = "in_chat_id"
$$;


--
-- Name: message_visible_to_account(bigint, bigint, boolean); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.message_visible_to_account(in_message_id bigint, in_account_id bigint, in_exclude_hidden_check boolean DEFAULT false) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
select			case	when	(
						"m"."created_at" >= "b"."oldest_visible_at"
					and	"m"."created_at" >= current_timestamp - "m"."expiration"
					and	"b"."active"
					and	(
							"in_exclude_hidden_check"
						or	not exists (
								select			1
									from		"chats"."hidden_messages"
									where		"account_id" = "b"."account_id"
										and	"message_id" = "m"."message_id"
							)
						)
					)
				then	true
				else	false
			end
	from		"chats"."messages" "m"
	join		"chats"."members" "b"
		using	("chat_id")
	where		"m"."message_id" = "in_message_id"
		and	"b"."account_id" = "in_account_id"
$$;


--
-- Name: message_visible_to_accounts(bigint); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.message_visible_to_accounts(in_message_id bigint) RETURNS bigint[]
    LANGUAGE sql STABLE
    AS $$
select			array_agg ("b"."account_id")
	from		"chats"."members" "b"
	join		"chats"."messages" "m"
		using	("chat_id")
	where		"m"."message_id" = "in_message_id"
		and	"m"."created_at" >= "b"."oldest_visible_at"
		and	"m"."created_at" >= current_timestamp - "m"."expiration"
		and	"b"."active"
		and	not exists (
				select			1
					from		"chats"."hidden_messages"
					where		"account_id" = "b"."account_id"
						and	"message_id" = "m"."message_id"
			)
$$;


--
-- Name: only_allow_hiding_visible_messages(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.only_allow_hiding_visible_messages() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	perform			1
		from		"new_data"
		where		"chats"."message_visible_to_account" (
					"message_id",
					"account_id",
					true
				) is not true;
	if found then
		raise exception 'Messages can only be hidden if they are visible to the account hiding them!';
	end if;
	return null;
end
$$;


--
-- Name: other_chat_members(integer, bigint); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.other_chat_members(in_chat_id integer, in_account_id bigint) RETURNS bigint[]
    LANGUAGE sql STABLE
    AS $$
with "results" (
	"account_id"
) as (
	select			"b"."account_id"
		from		"chats"."members" "b"
		join		"chats"."chats" "c"
			using	("chat_id")
		where		"b"."chat_id" = "in_chat_id"
			and	"c"."chat_type" <> 'channel'
			and	exists (
					select			1
						from		"chats"."members"
						where		"chat_id" = "b"."chat_id"
							and	"account_id" = "in_account_id"
				)
			and	"b"."account_id" <> "in_account_id"
	union all
	select			"owner_account_id"
		from		"chats"."chats"
		where		"chat_type" = 'channel'
			and	"chat_id" = "in_chat_id"
)
select			"array_agg" ("account_id")
	from		"results"
$$;


--
-- Name: other_direct_chat_member(integer, bigint); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.other_direct_chat_member(in_chat_id integer, in_account_id bigint) RETURNS bigint
    LANGUAGE sql STABLE
    AS $$
select			"account_id"
	from		"chats"."members" "b"
	where		"b"."chat_id" = "in_chat_id"
		and	"b"."account_id" <> "in_account_id"
		and	exists (
				select			1
					from		"chats"."chats"
					where		"chat_id" = "b"."chat_id"
						and	"chat_type" = 'direct'
			)
		and	exists (
				select			1
					from		"chats"."members"
					where		"chat_id" = "b"."chat_id"
						and	"account_id" = "in_account_id"
			)
$$;


--
-- Name: other_member_blocked(integer, bigint); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.other_member_blocked(in_chat_id integer, in_account_id bigint) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
select			case	when	(
						cardinality (
							"chats"."other_chat_members" (
								"in_chat_id",
								"in_account_id"
							)
						) = 1
					and	exists (
							select			1
								from		"public"."blocks"
								where		"account_id" = "in_account_id"
									and	"target_account_id" = (
											select			"other_chat_members"[1]
												from		"chats"."other_chat_members" (
															"in_chat_id",
															"in_account_id"
														)
										)
						)
					)
				then	true
				else	false
			end
$$;


--
-- Name: other_member_username(integer, bigint); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.other_member_username(in_chat_id integer, in_account_id bigint) RETURNS text
    LANGUAGE sql STABLE
    AS $$
select			case	when	cardinality (
						"chats"."other_chat_members" (
							"in_chat_id",
							"in_account_id"
						)
					) <> 1
				then	null
				else	(
						select			"username"
							from		"public"."accounts"
							where		"id" = (
										select			"other_chat_members"[1]
											from		"chats"."other_chat_members" (
														"in_chat_id",
														"in_account_id"
													)
									)
					)
			end
$$;


--
-- Name: set_latest_message_reaction_delete(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.set_latest_message_reaction_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	perform			1
		from		"chats"."messages"
		where		"message_id" = "old"."message_id";
	if found then
		insert into		"chats"."latest_message_reactions" (
						"message_id",
						"changed_at"
					)
			values		(
						"old"."message_id",
						current_timestamp
					)
			on conflict	("message_id")
				do	update
				set	"changed_at" = current_timestamp;
	end if;
	return "old";
end
$$;


--
-- Name: set_latest_message_reaction_insert(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.set_latest_message_reaction_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"chats"."latest_message_reactions" (
					"message_id",
					"changed_at"
				)
		values		(
					"new"."message_id",
					current_timestamp
				)
		on conflict	("message_id")
			do	update
			set	"changed_at" = current_timestamp;
	return "new";
end
$$;


--
-- Name: set_member_accepted_when_rejoining_chat(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.set_member_accepted_when_rejoining_chat() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if (
		"old"."active"
	and	not "new"."active"
	and	not "new"."accepted"
	) then
		"new"."accepted" = true;
	end if;
	return "new";
end
$$;


--
-- Name: set_member_active_when_creating_message(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.set_member_active_when_creating_message() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	update			"chats"."members"
		set		"accepted" = true
		where		"chat_id" = "new"."chat_id"
			and	"account_id" = "new"."created_by_account_id"
			and	not "accepted";
	return null;
end
$$;


--
-- Name: set_message_expiration(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.set_message_expiration() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if "new"."expiration" = '00:00:00' then
		select			"message_expiration"
			into		"new"."expiration"
			from		"chats"."chats"
			where		"chat_id" = "new"."chat_id";
		if not found then
			raise exception 'Chat ID % does not exist!',
				"new"."chat_id";
		end if;
	end if;
	return "new";
end
$$;


--
-- Name: subscriber_count(integer); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.subscriber_count(in_chat_id integer) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
select			"subscriber_count"
	from		"chats"."subscriber_counts"
	where		"chat_id" = "in_chat_id"
$$;


--
-- Name: unread_messages(integer, bigint); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.unread_messages(in_chat_id integer, in_account_id bigint) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
select			count (*)
	from		"chats"."messages" "m"
	where		"m"."chat_id" = "in_chat_id"
		and	"chats"."message_visible_to_account" (
				"m"."message_id",
				"in_account_id"
			)
		and	exists (
				select			1
					from		"chats"."members"
					where		"chat_id" = "m"."chat_id"
						and	"account_id" = "in_account_id"
						and	"latest_read_message_created_at" < "m"."created_at"
			)
$$;


--
-- Name: update_last_message_read_created_at_when_message_created(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.update_last_message_read_created_at_when_message_created() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	update			"chats"."members"
		set		"latest_read_message_created_at" = "new"."created_at"
		where		"chat_id" = "new"."chat_id"
			and	"account_id" = "new"."created_by_account_id"
			and	"latest_read_message_created_at" < "new"."created_at";
	return null;
end
$$;


--
-- Name: update_member_list_after_member_delete(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.update_member_list_after_member_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	with "new_member_lists" (
		"chat_id",
		"members"
	) as (
		select			"c"."chat_id",
					"array_agg" ("b"."account_id" order by "b"."account_id")
			from		"chats"."chats" "c"
			left join	"chats"."members" "b"
				using	("chat_id")
			where		"c"."chat_type" = 'direct'
				and	exists (
						select			1
							from		"old_data" "o"
							where		"o"."chat_id" = "b"."chat_id"
					)
			group by	1
	),
	"deleted" (
		"chat_id"
	) as (
		delete from		"chats"."member_lists" "l"
			using		"old_data" "o"
			where		"l"."chat_id" = "o"."chat_id"
				and	not exists (
						select			1
							from		"new_member_lists" "n"
							where		"n"."chat_id" = "o"."chat_id"
					)
			returning	"l"."chat_id"
	)
	update			"chats"."member_lists" "l"
		set		"members" = "n"."members"
		from		"new_member_lists" "n"
		where		"l"."chat_id" = "n"."chat_id"
			and	not exists (
					select			1
						from		"deleted"
						where		"chat_id" = "l"."chat_id"
				);
	return null;
end
$$;


--
-- Name: update_member_list_after_member_insert(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.update_member_list_after_member_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	with "new_member_lists" (
		"chat_id",
		"members"
	) as (
		select			"c"."chat_id",
					"array_agg" ("b"."account_id" order by "b"."account_id")
			from		"chats"."chats" "c"
			left join	"chats"."members" "b"
				using	("chat_id")
			where		"c"."chat_type" = 'direct'
				and	exists (
						select			1
							from		"new_data" "n"
							where		"n"."chat_id" = "b"."chat_id"
					)
			group by	1
	),
	"updated" (
		"chat_id"
	) as (
		update			"chats"."member_lists" "l"
			set		"members" = "n"."members"
			from		"new_member_lists" "n"
			where		"n"."chat_id" = "l"."chat_id"
			returning	"l"."chat_id"
	)
	insert into		"chats"."member_lists" as "l" (
					"chat_id",
					"members"
				)
	select			"n"."chat_id",
				"n"."members"
		from		"new_member_lists" "n"
		where		not exists (
					select			1
						from		"updated" "u"
						where		"u"."chat_id" = "n"."chat_id"
				)
		on conflict	("chat_id")
			do	update
			set	"members" = (
					select			"members"
						from		"new_member_lists"
						where		"chat_id" = "l"."chat_id"
				);
	return null;
end
$$;


--
-- Name: update_member_list_after_member_update(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.update_member_list_after_member_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
	"var_new_member_list"		int8[];
begin
	with "new_member_list" (
		"members"
	) as (
		select			"array_agg" ("b"."account_id" order by "b"."account_id")
			from		"chats"."chats" "c"
			left join	"chats"."members" "b"
				using	("chat_id")
			where		"c"."chat_type" = 'direct'
				and	"b"."chat_id" = "new"."chat_id"
	)
	update			"chats"."member_lists" "l"
		set		"members" = "n"."members"
		from		"new_member_list" "n"
		where		"l"."chat_id" = "new"."chat_id";
	return null;
end
$$;


--
-- Name: update_member_oldest_visible_when_leaving_or_rejoining_chat(); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.update_member_oldest_visible_when_leaving_or_rejoining_chat() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if "old"."active" <> "new"."active" then
		"new"."oldest_visible_at" = current_timestamp;
	end if;
	return "new";
end
$$;


--
-- Name: username(bigint); Type: FUNCTION; Schema: chats; Owner: -
--

CREATE FUNCTION chats.username(in_account_id bigint) RETURNS text
    LANGUAGE sql STABLE
    AS $$
select			"username"
	from		"public"."accounts"
	where		"id" = "in_account_id"
$$;


--
-- Name: chat_events_basic(bigint, smallint, integer, smallint, bigint, smallint); Type: FUNCTION; Schema: common_logic; Owner: -
--

CREATE FUNCTION common_logic.chat_events_basic(in_account_id bigint, in_api_version smallint, in_chat_id integer DEFAULT NULL::integer, in_upgrade_from_api_version smallint DEFAULT NULL::smallint, in_greater_than_event_id bigint DEFAULT NULL::bigint, in_page_size smallint DEFAULT 20) RETURNS SETOF mastodon_chats_logic.event_basic
    LANGUAGE sql STABLE
    SET plan_cache_mode TO 'force_custom_plan'
    AS $$
select			"e"."event_id",
			"e"."chat_id",
			"e"."event_type",
			"e"."timestamp"
	from		"chat_events"."events" "e"
	where		case
				when	"in_chat_id" is not null
				then	"e"."chat_id" = "in_chat_id"
				else	true
			end
		and	case
				when	"in_greater_than_event_id" is not null
				then	"e"."event_id" > "in_greater_than_event_id"
				else	true
			end
		and	exists (
				select			1
					from		"chats"."members" "b"
					where		"b"."account_id" = "in_account_id"
						and	"b"."chat_id" = "e"."chat_id"
						and	"b"."active"
						and	(
								"e"."event_type" = 'chat_created'
							or	"b"."oldest_visible_at" <= "e"."timestamp"
							)
			) -- Active members/subscribers should see all events newer than their oldest_visible_at, as well as chat_created events
		and	not (
				"e"."event_type" = 'message_hidden'
			and	not exists (
					select			1
						from		"chat_events"."message_hides" "v"
						where		"v"."event_id" = "e"."event_id"
							and	"v"."account_id" = "in_account_id"
				)
			) -- Message hides only visible to account that hid the messages
		and	not (
				"e"."event_type" = 'chat_silenced'
			and	not exists (
					select			1
						from		"chat_events"."chat_silences" "s"
						where		"s"."event_id" = "e"."event_id"
							and	"s"."account_id" = "in_account_id"
				)
			) -- Chat silences only visible to account that silenced the chat
		and	not (
				"e"."event_type" = 'chat_unsilenced'
			and	not exists (
					select			1
						from		"chat_events"."chat_unsilences" "u"
						where		"u"."event_id" = "e"."event_id"
							and	"u"."account_id" = "in_account_id"
				)
			) -- Chat unsilences only visible to account that unsilenced the chat
		and	not (
				"e"."event_type" = 'subscriber_left'
			and	not exists (
					select			1
						from		"chat_events"."subscriber_leaves" "l"
						where		"l"."event_id" = "e"."event_id"
							and	"l"."account_id" = "in_account_id"
				)
			) -- Subscriber leaves only visible to account that left
		and	not (
				"e"."event_type" = 'subscriber_rejoined'
			and	not exists (
					select			1
						from		"chat_events"."subscriber_rejoins" "r"
						where		"r"."event_id" = "e"."event_id"
							and	"r"."account_id" = "in_account_id"
				)
			) -- Subscriber rejoins only visible to account that rejoined
		and	case
				when	"in_api_version" <= "in_upgrade_from_api_version"
				then	false
				when	(
						"in_api_version" > "in_upgrade_from_api_version"
					and	"in_upgrade_from_api_version" = 1
					)
				then	(
						"e"."event_type" = 'message_created'
					and	exists (
							select			1
								from		"chat_events"."message_creations" "c"
								join		"chats"."messages" "m"
									using	("message_id")
								where		"c"."event_id" = "e"."event_id"
									and	"m"."message_type" = 'media'
						)
					) -- Upgrade from API v1 - media messages
				else	true
			end
		and	not (
				"e"."event_type" = 'message_edited'
			and	"in_api_version" < 2
			) -- Message editing (for media messages when videos are uploaded to Rumble) only returned when API version >= 2
			-- We don't return these for API upgrades because they are only relevant for media messages which were not supported in API v1
union all
select			"e"."event_id",
			"e"."chat_id",
			"e"."event_type",
			"e"."timestamp"
	from		"chat_events"."events" "e"
	where		"in_upgrade_from_api_version" is null
		and	"e"."event_id" in (
				select			max ("x"."event_id")
					from		"chat_events"."events" "x"
					join		"chat_events"."member_leaves" "l"
						using	("event_id")
					where		"x"."event_type" = 'member_left'
						and	"l"."account_id" = "in_account_id"
						and	case
								when	"in_chat_id" is not null
								then	"x"."chat_id" = "in_chat_id"
								else	true
							end
						and	case
								when	"in_greater_than_event_id" is not null
								then	"x"."event_id" > "in_greater_than_event_id"
								else	true
							end
						and	exists (
								select			1
									from		"chats"."members" "b"
									join		"chats"."chats" "c"
										using	("chat_id")
									where		"b"."account_id" = "in_account_id"
										and	"b"."chat_id" = "x"."chat_id"
										and	"b"."active"
							)
					group by	"x"."chat_id"
			) -- Active members should see their most recent leave event
union all
select			"e"."event_id",
			"e"."chat_id",
			"e"."event_type",
			"e"."timestamp"
	from		"chat_events"."events" "e"
	where		"in_upgrade_from_api_version" is null
		and	case
				when	"in_chat_id" is not null
				then	"e"."chat_id" = "in_chat_id"
				else	true
			end
		and	case
				when	"in_greater_than_event_id" is not null
				then	"e"."event_id" > "in_greater_than_event_id"
				else	true
			end
		and	exists (
				select			1
					from		"chats"."members" "b"
					where		"b"."account_id" = "in_account_id"
						and	"b"."chat_id" = "e"."chat_id"
						and	not "b"."active"
						and	"b"."oldest_visible_at" <= "e"."timestamp"
						and	(
								(
									"e"."event_type" = 'member_left'
								and	exists (
										select			1
											from		"chat_events"."member_leaves" "l"
											where		"l"."event_id" = "e"."event_id"
												and	"l"."account_id" = "in_account_id"
									)
								)
							or	(
									"e"."event_type" = 'subscriber_left'
								and	exists (
										select			1
											from		"chat_events"."subscriber_leaves" "l"
											where		"l"."event_id" = "e"."event_id"
												and	"l"."account_id" = "in_account_id"
									)
								)
							)
			) -- Inactive members/subcribers should see an event when they leave
		and	not (
				"e"."event_type" = 'subscriber_left'
			and	not exists (
					select			1
						from		"chat_events"."subscriber_leaves" "l"
						where		"l"."event_id" = "e"."event_id"
							and	"l"."account_id" = "in_account_id"
				)
			) -- Subscriber leaves only visible to account that left
union all
select			"e"."event_id",
			"e"."chat_id",
			"e"."event_type",
			"e"."timestamp"
	from		"chat_events"."events" "e"
	where		"in_upgrade_from_api_version" is null
		and	case
				when	"in_chat_id" is not null
				then	"e"."chat_id" = "in_chat_id"
				else	true
			end
		and	case
				when	"in_greater_than_event_id" is not null
				then	"e"."event_id" > "in_greater_than_event_id"
				else	true
			end
		and	exists (
				select			1
					from		"chats"."deleted_members" "b"
					where		"b"."account_id" = "in_account_id"
						and	"b"."chat_id" = "e"."chat_id"
						and	"e"."event_type" = 'chat_deleted'
			) -- Former members/subscribers of deleted chats should see an event when the chat was deleted
$$;


--
-- Name: json_format_timestamp(timestamp without time zone); Type: FUNCTION; Schema: common_logic; Owner: -
--

CREATE FUNCTION common_logic.json_format_timestamp(in_timestamp timestamp without time zone) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
select			to_char (
				"in_timestamp",
				'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'
			)
$$;


--
-- Name: json_format_timestamp(timestamp with time zone); Type: FUNCTION; Schema: common_logic; Owner: -
--

CREATE FUNCTION common_logic.json_format_timestamp(in_timestamp timestamp with time zone) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
select			to_char (
				"in_timestamp" at time zone 'UTC',
				'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'
			)
$$;


--
-- Name: tag_name(bigint); Type: FUNCTION; Schema: common_logic; Owner: -
--

CREATE FUNCTION common_logic.tag_name(in_tag_id bigint) RETURNS text
    LANGUAGE sql STABLE
    AS $$
select			"name"
	from		"public"."tags"
	where		"id" = "in_tag_id"
$$;


--
-- Name: banned_words_regular_expression(); Type: FUNCTION; Schema: configuration; Owner: -
--

CREATE FUNCTION configuration.banned_words_regular_expression() RETURNS text
    LANGUAGE sql STABLE
    AS $$
select			(
				'('
			||	"string_agg" ("word", '|')
			||	')'
			)
	from		"configuration"."banned_words"
$$;


--
-- Name: base_url(); Type: FUNCTION; Schema: configuration; Owner: -
--

CREATE FUNCTION configuration.base_url() RETURNS text
    LANGUAGE sql STABLE
    AS $$
select			(
				case
					when	"configuration"."value" ('RAILS_ENV') = 'production'
					then	'https'
					else	'http'
				end
			||	'://'
			||	"configuration"."value" ('WEB_DOMAIN')
			)
$$;


--
-- Name: feature_id(text); Type: FUNCTION; Schema: configuration; Owner: -
--

CREATE FUNCTION configuration.feature_id(in_name text) RETURNS smallint
    LANGUAGE sql STABLE
    AS $$
select			"feature_id"
	from		"configuration"."features"
	where		"name" = "in_name"
$$;


--
-- Name: feature_setting_value(text, text); Type: FUNCTION; Schema: configuration; Owner: -
--

CREATE FUNCTION configuration.feature_setting_value(in_feature text, in_name text) RETURNS text
    LANGUAGE sql STABLE
    AS $$
select			"s"."value"
	from		"configuration"."feature_settings" "s"
	join		"configuration"."features" "f"
		using	("feature_id")
	where		"f"."name" = "in_feature"
		and	"s"."name" = "in_name"
$$;


--
-- Name: link_url(); Type: FUNCTION; Schema: configuration; Owner: -
--

CREATE FUNCTION configuration.link_url() RETURNS text
    LANGUAGE sql STABLE
    AS $$
select			(
				case
					when	"configuration"."value" ('RAILS_ENV') = 'production'
					then	'https'
					else	'http'
				end
			||	'://links.'
			||	"configuration"."value" ('WEB_DOMAIN')
			)
$$;


--
-- Name: send_elwood_reload_configuration_notification(); Type: FUNCTION; Schema: configuration; Owner: -
--

CREATE FUNCTION configuration.send_elwood_reload_configuration_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	notify "elwood_reload_configuration";
	return null;
end
$$;


--
-- Name: storage_base_url(); Type: FUNCTION; Schema: configuration; Owner: -
--

CREATE FUNCTION configuration.storage_base_url() RETURNS text
    LANGUAGE sql STABLE
    AS $$
select			case
				when	"configuration"."value" ('S3_ENABLED') = 'true'
				then	(
						"configuration"."value" ('S3_PROTOCOL')
					||	'://'
					||	"configuration"."value" ('S3_ALIAS_HOST')
					)
				else	"configuration"."base_url" ()
			end
$$;


--
-- Name: trending_status_setting_update_from_api_view(); Type: FUNCTION; Schema: configuration; Owner: -
--

CREATE FUNCTION configuration.trending_status_setting_update_from_api_view() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if "old"."name" is distinct from "new"."name" then
		raise exception 'Attempted to modify "name" when updating "api"."trending_status_settings".  This is not possible!';
	elsif "old"."value_type" is distinct from "new"."value_type" then
		raise exception 'Attempted to modify "value_type" when updating "api"."trending_status_settings".  This is not possible!';
	end if;
	if "old"."value" is distinct from "new"."value" then
		update			"configuration"."feature_settings"
			set		"value" = "new"."value"
			where		"feature_id" = "configuration"."feature_id" ('trending_statuses')
				and	"name" = "new"."name";
	end if;
	return "new";
end
$$;


--
-- Name: validate_feature_setting(); Type: FUNCTION; Schema: configuration; Owner: -
--

CREATE FUNCTION configuration.validate_feature_setting() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
	"var_sql"	text;
begin
	begin
		"var_sql" := 'select ' || quote_literal ("new"."value") || '::' || "new"."value_type";
		execute "var_sql";
	exception when others then
		raise exception 'Setting % must be of type %, but the value % cannot be cast as that type!',
			quote_literal ("new"."name"),
			"new"."value_type",
			quote_literal ("new"."value");
	end;
	return "new";
end
$$;


--
-- Name: value(text); Type: FUNCTION; Schema: configuration; Owner: -
--

CREATE FUNCTION configuration.value(in_name text) RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
declare
	"var_output"		text;
begin
	select			"value"
		into		"var_output"
		from		"configuration"."global"
		where		"name" = "in_name";
	if not found then
		raise exception 'Configuration value % not found!',
			"quote_literal" ("in_name");
	end if;
	return "var_output";
end
$$;


--
-- Name: delete_expired_chat_messages(); Type: PROCEDURE; Schema: cron; Owner: -
--

CREATE PROCEDURE cron.delete_expired_chat_messages()
    LANGUAGE sql
    AS $$
delete from		"chats"."messages"
	where		"created_at" at time zone 'UTC' + "expiration" <= current_timestamp at time zone 'UTC';
delete from		"chats"."deleted_messages"
	where		"created_at" at time zone 'UTC' + "expiration" <= current_timestamp at time zone 'UTC';
$$;


--
-- Name: delete_expired_status_tags_cache(); Type: PROCEDURE; Schema: cron; Owner: -
--

CREATE PROCEDURE cron.delete_expired_status_tags_cache()
    LANGUAGE sql
    AS $$
delete from		"cache"."status_tags"
	where		"created_at" < (
				current_timestamp
			-	"configuration"."feature_setting_value" (
					'status_tag_cache',
					'statuses_count_interval'
				)::interval
			);
delete from		"cache"."group_status_tags"
	where		"created_at" < (
				current_timestamp
			-	"configuration"."feature_setting_value" (
					'status_tag_cache',
					'statuses_count_interval'
				)::interval
			);
$$;


--
-- Name: refresh_trending_groups(); Type: PROCEDURE; Schema: cron; Owner: -
--

CREATE PROCEDURE cron.refresh_trending_groups()
    LANGUAGE sql
    AS $$
refresh materialized view
	concurrently
			"trending_groups"."trending_group_scores"
$$;


--
-- Name: refresh_trending_statuses(); Type: PROCEDURE; Schema: cron; Owner: -
--

CREATE PROCEDURE cron.refresh_trending_statuses()
    LANGUAGE sql
    AS $$
refresh materialized view
	concurrently	"trending_statuses"."recent_statuses_from_followed_accounts";
refresh materialized view
	concurrently	"trending_statuses"."replies_by_nonfollowers";
refresh materialized view
	concurrently	"trending_statuses"."reblogs_by_nonfollowers";
refresh materialized view
	concurrently	"trending_statuses"."favourites_by_nonfollowers";
refresh materialized view
	concurrently	"trending_statuses"."trending_statuses_viral";
refresh materialized view
	concurrently	"trending_statuses"."trending_statuses_popular";
refresh materialized view
	concurrently	"trending_statuses"."trending_statuses";
$$;


--
-- Name: refresh_trending_tags(); Type: PROCEDURE; Schema: cron; Owner: -
--

CREATE PROCEDURE cron.refresh_trending_tags()
    LANGUAGE sql
    AS $$
refresh materialized view
	concurrently	"trending_tags"."trending_tag_scores";
refresh materialized view
	concurrently	"trending_tags"."trending_tags";
$$;


--
-- Name: update_daily_active_users(); Type: PROCEDURE; Schema: cron; Owner: -
--

CREATE PROCEDURE cron.update_daily_active_users()
    LANGUAGE sql
    AS $$
insert into		"statistics"."daily_active_users"
select			current_date,
			"id"
	from		"public"."users"
	where		"current_sign_in_at" > current_timestamp - interval '1 day';
insert into		"statistics"."daily_active_user_counts"
select			current_date,
			count (1)
	from		"public"."users"
	where		"current_sign_in_at" > current_timestamp - interval '1 day';
$$;


--
-- Name: indexes(); Type: FUNCTION; Schema: database; Owner: -
--

CREATE FUNCTION database.indexes() RETURNS SETOF database.index
    LANGUAGE sql STABLE
    AS $$
select			"i"."indexrelid",
			"n"."nspname",
			"r"."relname",
			"c"."relname",
			"m"."amname",
			array (
				select			(
								case
									when	"a"."attnum" > 0
									then	"a"."attname"
									else	"pg_catalog"."pg_get_indexdef" (
											"i"."indexrelid",
											"o"."ord"::int4,
											true
										)
								end
							||	case
									when	"m"."amname" <> 'btree'
									then	''
									when	(
											("l"."option" & 1) = 1
										and	("l"."option" & 2) = 2
										)
									then	' desc'
									when	(
											("l"."option" & 1) = 1
										and	("l"."option" & 2) <> 2
										)
									then	' desc nulls last'
									when	(
											("l"."option" & 1) <> 1
										and	("l"."option" & 2) = 2
										)
									then	' nulls first'
									when	(
											("l"."option" & 1) <> 1
										and	("l"."option" & 2) <> 2
										)
									then	''
								end
							)
					from		"unnest" ("i"."indkey", "i"."indoption") with ordinality as "o" ("attnum", "option", "ord")
					left join	"pg_catalog"."pg_attribute" "a"
						on	"a"."attrelid" = "i"."indrelid"
						and	"a"."attnum" = "o"."attnum"
					cross join	lateral (
								select			"o"."option"
							) as "l"
					order by	"o"."ord"
			),
			"i"."indisunique",
			"pg_get_expr" (
				"i"."indpred",
				"i"."indrelid"
			),
			"pg_relation_size" ("i"."indexrelid"),
			"s"."idx_scan",
			"s"."last_idx_scan",
			"pg_catalog"."obj_description" (
				"c"."oid",
				'pg_class'
			)
	from		"pg_catalog"."pg_index" "i"
	join		"pg_catalog"."pg_class" "r"
		on	"i"."indrelid" = "r"."oid"
	join		"pg_catalog"."pg_class" "c"
		on	"i"."indexrelid" = "c"."oid"
	join		"pg_catalog"."pg_namespace" "n"
		on	"r"."relnamespace" = "n"."oid"
	join		"pg_catalog"."pg_am" "m"
		on	"c"."relam" = "m"."oid"
	join		"pg_catalog"."pg_stat_all_indexes" "s"
		on	"c"."oid" = "s"."indexrelid"
	where		not exists (
				select 1
					from		"pg_catalog"."pg_roles" "x"
					where		"x"."oid" = "n"."nspowner"
						and	"x"."rolname" = 'postgres'
			)
	order by	2, 3, 4
$$;


--
-- Name: redundant_indexes(); Type: FUNCTION; Schema: database; Owner: -
--

CREATE FUNCTION database.redundant_indexes() RETURNS TABLE(schema text, "table" text, index text, definition text, partial_predicate text, size bigint, covering_index text, covering_definition text)
    LANGUAGE sql STABLE
    AS $$
select			"a"."schema",
			"a"."table",
			"a"."index",
			"a"."definition",
			"a"."partial_predicate",
			"a"."size",
			"b"."index",
			"b"."definition"
	from		"database"."indexes" () "a"
	join		"database"."indexes" () "b"
		on	"a"."schema" = "b"."schema"
		and	"a"."table" = "b"."table"
		and	"a"."index_id" != "b"."index_id"
		and	"a"."partial_predicate" is not distinct from "b"."partial_predicate"
	where		not "a"."unique"
		and	"b"."definition" @> "a"."definition"
		and	"pg_catalog"."position" (
				"array_to_string" (
					"b"."definition",
					','
				),
				"array_to_string" (
					"a"."definition",
					','
				)
			) = 1
	order by	1, 2, 3
$$;


--
-- Name: unused_indexes(); Type: FUNCTION; Schema: database; Owner: -
--

CREATE FUNCTION database.unused_indexes() RETURNS SETOF database.index
    LANGUAGE sql STABLE
    AS $$
select			"i"."index_id",
			"i"."schema",
			"i"."table",
			"i"."index",
			"i"."access_method",
			"i"."definition",
			"i"."unique",
			"i"."partial_predicate",
			"i"."size",
			"i"."scans",
			"i"."last_scan",
			"i"."comment"
	from		"database"."indexes" () "i"
	where		(
				"i"."scans" = 0
			or	"i"."last_scan" < current_timestamp - interval '1 day'
			)
		and	not exists (
				select			1
					from		"pg_catalog"."pg_constraint" "x"
					where		"x"."contype" = 'p'
						and	"x"."conindid" = "i"."index_id"
			)
	order by	2, 3, 4
$$;


--
-- Name: configuration(); Type: FUNCTION; Schema: elwood_api; Owner: -
--

CREATE FUNCTION elwood_api.configuration() RETURNS SETOF elwood_api.configuration
    LANGUAGE sql STABLE
    AS $$
select			"notification_channel",
			"callback_sql",
			"sleep_after_callback"
	from		"configuration"."elwood"
	where		"enabled"
	order by	1
$$;


--
-- Name: process_account_follower_statistics_queue(); Type: PROCEDURE; Schema: elwood_api; Owner: -
--

CREATE PROCEDURE elwood_api.process_account_follower_statistics_queue()
    LANGUAGE plpgsql
    AS $$
begin
	create temp table	"account_follower_statistics_adjustments" (
					"account_id"		int8		not null,
					"adjustment"		int4		not null,
					primary key		("account_id")
				);
	with "queue" (
		"account_id",
		"adjustment"
	) as (
		delete from		"queues"."account_follower_statistics"
			returning	"account_id",
					"adjustment"
	)
	insert into		"account_follower_statistics_adjustments"
	select			"q"."account_id",
				sum ("q"."adjustment") "adjustment"
		from		"queue" "q"
		where		exists (
					select			1
						from		"public"."accounts"
						where		"id" = "q"."account_id"
				)
		group by	1;
	with "deleted" ("account_id") as (
		delete from		"statistics"."account_followers" "a"
			using		"account_follower_statistics_adjustments" "j"
			where		"j"."account_id" = "a"."account_id"
				and	"a"."followers_count" + "j"."adjustment" = 0
			returning	"a"."account_id"
	),
	"updated" ("account_id") as (
		update			"statistics"."account_followers" "a"
			set		"followers_count" = "a"."followers_count" + "j"."adjustment"
			from		"account_follower_statistics_adjustments" "j"
			where		"j"."account_id" = "a"."account_id"
				and	not exists (
						select			1
							from		"deleted"
							where		"account_id" = "j"."account_id"
					)
			returning	"a"."account_id"
	)
	insert into		"statistics"."account_followers" as "a" (
					"account_id",
					"followers_count"
				)
	select			"j"."account_id",
				"j"."adjustment"
		from		"account_follower_statistics_adjustments" "j"
		where		not exists (
					select			1
						from		"updated"
						where		"account_id" = "j"."account_id"
				)
			and	not exists (
					select			1
						from		"deleted"
						where		"account_id" = "j"."account_id"
				)
			and	"j"."adjustment" <> 0
		on conflict	("account_id")
			do	update
			set	"followers_count" = "a"."followers_count" + "excluded"."followers_count";
	drop table		"account_follower_statistics_adjustments";
end
$$;


--
-- Name: process_account_following_statistics_queue(); Type: PROCEDURE; Schema: elwood_api; Owner: -
--

CREATE PROCEDURE elwood_api.process_account_following_statistics_queue()
    LANGUAGE plpgsql
    AS $$
begin
	create temp table	"account_following_statistics_adjustments" (
					"account_id"		int8		not null,
					"adjustment"		int4		not null,
					primary key		("account_id")
				);
	with "queue" (
		"account_id",
		"adjustment"
	) as (
		delete from		"queues"."account_following_statistics"
			returning	"account_id",
					"adjustment"
	)
	insert into		"account_following_statistics_adjustments"
	select			"q"."account_id",
				sum ("q"."adjustment") "adjustment"
		from		"queue" "q"
		where		exists (
					select			1
						from		"public"."accounts"
						where		"id" = "q"."account_id"
				)
		group by	1;
	with "deleted" ("account_id") as (
		delete from		"statistics"."account_following" "a"
			using		"account_following_statistics_adjustments" "j"
			where		"j"."account_id" = "a"."account_id"
				and	"a"."following_count" + "j"."adjustment" = 0
			returning	"a"."account_id"
	),
	"updated" ("account_id") as (
		update			"statistics"."account_following" "a"
			set		"following_count" = "a"."following_count" + "j"."adjustment"
			from		"account_following_statistics_adjustments" "j"
			where		"j"."account_id" = "a"."account_id"
				and	not exists (
						select			1
							from		"deleted"
							where		"account_id" = "j"."account_id"
					)
			returning	"a"."account_id"
	)
	insert into		"statistics"."account_following" as "a" (
					"account_id",
					"following_count"
				)
	select			"j"."account_id",
				"j"."adjustment"
		from		"account_following_statistics_adjustments" "j"
		where		not exists (
					select			1
						from		"updated"
						where		"account_id" = "j"."account_id"
				)
			and	not exists (
					select			1
						from		"deleted"
						where		"account_id" = "j"."account_id"
				)
			and	"j"."adjustment" <> 0
		on conflict	("account_id")
			do	update
			set	"following_count" = "a"."following_count" + "excluded"."following_count";
	drop table		"account_following_statistics_adjustments";
end
$$;


--
-- Name: process_account_status_statistics_queue(); Type: PROCEDURE; Schema: elwood_api; Owner: -
--

CREATE PROCEDURE elwood_api.process_account_status_statistics_queue()
    LANGUAGE plpgsql
    AS $$
begin
	create temp table	"account_status_statistics_adjustments" (
					"account_id"		int8		not null,
					"adjustment"		int4		not null,
					primary key		("account_id")
				);
	with "queue" (
		"account_id",
		"adjustment"
	) as (
		delete from		"queues"."account_status_statistics"
			returning	"account_id",
					"adjustment"
	)
	insert into		"account_status_statistics_adjustments"
	select			"q"."account_id",
				sum ("q"."adjustment") "adjustment"
		from		"queue" "q"
		where		exists (
					select			1
						from		"public"."accounts"
						where		"id" = "q"."account_id"
				)
		group by	1;
	with "latest_statuses" (
		"account_id",
		"group_status",
		"latest_status"
	) as (
		select			"s"."account_id",
					"s"."group_id" is not null,
					max ("s"."created_at")
			from		"public"."statuses" "s"
			where		"s"."deleted_at" is null
				and	"s"."in_reply_to_id" is null
				and	exists (
						select			1
							from		"account_status_statistics_adjustments"
							where		"account_id" = "s"."account_id"
					)
			group by	1, 2
	),
	"deleted" ("account_id") as (
		delete from		"statistics"."account_statuses" "a"
			using		"account_status_statistics_adjustments" "j"
			where		"a"."account_id" = "j"."account_id"
				and	"a"."statuses_count" + "j"."adjustment" = 0
			returning	"a"."account_id"
	),
	"updated" ("account_id") as (
		update			"statistics"."account_statuses" "a"
			set		"statuses_count" = "a"."statuses_count" + "j"."adjustment",
					"last_status_at" = "s"."latest_status",
					"last_following_status_at" = "s2"."latest_status"
			from		"account_status_statistics_adjustments" "j"
			join		(
						select			"account_id",
									max ("latest_status")
							from		"latest_statuses"
							group by	1
					) "s" (
						"account_id",
						"latest_status"
					)
				using	("account_id")
			left join	"latest_statuses" "s2"
				on	"s2"."account_id" = "j"."account_id"
				and	not "s2"."group_status"
			where		"a"."account_id" = "j"."account_id"
				and	not exists (
						select			1
							from		"deleted"
							where		"account_id" = "j"."account_id"
					)
			returning	"a"."account_id"
	)
	insert into		"statistics"."account_statuses" as "a" (
					"account_id",
					"statuses_count",
					"last_status_at",
					"last_following_status_at"
				)
	select			"j"."account_id",
				"j"."adjustment",
				"s"."latest_status",
				"s2"."latest_status"
		from		"account_status_statistics_adjustments" "j"
		join		(
					select			"account_id",
								max ("latest_status")
						from		"latest_statuses"
						group by	1
				) "s" (
					"account_id",
					"latest_status"
				)
			using	("account_id")
		left join	"latest_statuses" "s2"
			on	"s2"."account_id" = "j"."account_id"
			and	not "s2"."group_status"
		where		not exists (
					select			1
						from		"updated"
						where		"account_id" = "j"."account_id"
				)
			and	not exists (
					select			1
						from		"deleted"
						where		"account_id" = "j"."account_id"
				)
			and	"j"."adjustment" <> 0
		on conflict	("account_id")
			do	update
			set	"statuses_count" = "a"."statuses_count" + "excluded"."statuses_count",
				"last_status_at" = coalesce (
					"excluded"."last_status_at",
					case	when	"a"."statuses_count" + "excluded"."statuses_count" <> 0
						then	"a"."last_status_at"
					end
				);
	drop table		"account_status_statistics_adjustments";
end
$$;


--
-- Name: process_chat_events_queue(); Type: PROCEDURE; Schema: elwood_api; Owner: -
--

CREATE PROCEDURE elwood_api.process_chat_events_queue()
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
declare
	"var_event"		record;
begin
	for "var_event" in (
		with "deleted" (
			"chat_id",
			"timestamp",
			"event_type",
			"payload"
		) as (
			delete from		"queues"."chat_events"
				returning	"chat_id",
						"timestamp",
						"event_type",
						"payload"
		)
		select			"chat_id",
					"timestamp",
					"event_type",
					"payload"
			from		"deleted"
			order by	"timestamp",
					"event_type"
	) loop
		call			"mastodon_chats_logic"."event_create" (
						"var_event"."chat_id",
						"var_event"."timestamp",
						"var_event"."event_type",
						"var_event"."payload"
					);
	end loop;
end
$$;


--
-- Name: process_chat_subscribers_queue(); Type: PROCEDURE; Schema: elwood_api; Owner: -
--

CREATE PROCEDURE elwood_api.process_chat_subscribers_queue()
    LANGUAGE plpgsql
    AS $$
begin
	create temp table	"chat_subscriber_adjustments" (
					"chat_id"		int4		not null,
					"adjustment"		int4		not null,
					primary key		("chat_id")
				);
	with "queue" (
		"chat_id",
		"adjustment"
	)  as (
		delete from		"queues"."chat_subscribers"
			returning	"chat_id",
					"adjustment"
	)
	insert into		"chat_subscriber_adjustments" (
					"chat_id",
					"adjustment"
				)
	select			"q"."chat_id",
				sum ("q"."adjustment")
		from		"queue" "q"
		where		exists (
					select			1
						from		"chats"."chats" "c"
						where		"c"."chat_id" = "q"."chat_id"
				)
		group by	1;
	with "updated" ("chat_id") as (
		update			"chats"."subscriber_counts" "s"
			set		"subscriber_count" = "s"."subscriber_count" + "j"."adjustment"
			from		"chat_subscriber_adjustments" "j"
			where		"j"."chat_id" = "s"."chat_id"
			returning	"j"."chat_id"
	)
	insert into		"chats"."subscriber_counts" as "s" (
					"chat_id",
					"subscriber_count"
				)
	select			"j"."chat_id",
				"j"."adjustment"
		from		"chat_subscriber_adjustments" "j"
		where		not exists (
					select			1
						from		"updated" "u"
						where		"u"."chat_id" = "j"."chat_id"
				)
			and	"j"."adjustment" <> 0
		on conflict	("chat_id")
			do	update
			set	"subscriber_count" = "s"."subscriber_count" + "excluded"."subscriber_count";
	drop table		"chat_subscriber_adjustments";
end
$$;


--
-- Name: process_poll_option_statistics_queue(); Type: PROCEDURE; Schema: elwood_api; Owner: -
--

CREATE PROCEDURE elwood_api.process_poll_option_statistics_queue()
    LANGUAGE plpgsql
    AS $$
begin
	create temp table	"poll_vote_adjustments" (
					"poll_id"		int8		not null,
					"option_number"		int4		not null,
					"adjustment"		int4		not null,
					primary key		(
									"poll_id",
									"option_number"
								)
				);
	with "batch" ("ctid") as (
		select			"ctid"
			from		"queues"."poll_option_statistics"
			order by	1
			limit		250000
	),
	"queue" (
		"poll_id",
		"option_number",
		"adjustment"
	) as (
		delete from		"queues"."poll_option_statistics" "q"
			where		exists (
						select			1
							from		"batch" "b"
							where		"b"."ctid" = "q"."ctid"
					)
			returning	"poll_id",
					"option_number",
					"adjustment"
	)
	insert into		"pg_temp"."poll_vote_adjustments" (
					"poll_id",
					"option_number",
					"adjustment"
				)
	select			"q"."poll_id",
				"q"."option_number",
				"sum" ("q"."adjustment")
		from		"queue" "q"
		where		exists (
					select			1
						from		"polls"."options" "o"
						where		"o"."poll_id" = "q"."poll_id"
							and	"o"."option_number" = "q"."option_number"
				)
		group by	1, 2
			having	"sum" ("q"."adjustment") <> 0;
	analyze			"pg_temp"."poll_vote_adjustments";
	with "deleted" (
		"poll_id",
		"option_number"
	) as (
		delete from		"statistics"."poll_options" "s"
			using		"pg_temp"."poll_vote_adjustments" "j"
			where		"j"."poll_id" = "s"."poll_id"
				and	"j"."option_number" = "s"."option_number"
				and	"s"."votes" + "j"."adjustment" = 0
			returning	"s"."poll_id",
					"s"."option_number"
	),
	"updated" (
		"poll_id",
		"option_number"
	) as (
		update			"statistics"."poll_options" "s"
			set		"votes" = "s"."votes" + "j"."adjustment"
			from		"pg_temp"."poll_vote_adjustments" "j"
			where		"j"."poll_id" = "s"."poll_id"
				and	"j"."option_number" = "s"."option_number"
				and	not exists (
						select			1
							from		"deleted" "d"
							where		"d"."poll_id" = "j"."poll_id"
								and	"d"."option_number" = "j"."option_number"
					)
			returning	"s"."poll_id",
					"s"."option_number"
	)
	insert into		"statistics"."poll_options" as "s" (
					"poll_id",
					"option_number",
					"votes"
				)
	select			"j"."poll_id",
				"j"."option_number",
				"j"."adjustment"
		from		"pg_temp"."poll_vote_adjustments" "j"
		where		not exists (
					select			1
						from		"updated" "u"
						where		"u"."poll_id" = "j"."poll_id"
							and	"u"."option_number" = "j"."option_number"
				)
			and	not exists (
					select			1
						from		"deleted" "d"
						where		"d"."poll_id" = "j"."poll_id"
							and	"d"."option_number" = "j"."option_number"
				)
		on conflict	(
					"poll_id",
					"option_number"
				)
			do	update
			set	"votes" = "s"."votes" + "excluded"."votes";
	with "vote_adjustments" (
		"poll_id",
		"adjustment"
	) as (
		select			"poll_id",
					sum ("adjustment")
			from		"pg_temp"."poll_vote_adjustments"
			group by	1
	),
	"new_voter_counts" (
		"poll_id",
		"voters"
	) as (
		select			"poll_id",
					count (distinct "v"."account_id")
			from		"polls"."options" "o"
			left join	"polls"."votes" "v"
				using	(
						"poll_id",
						"option_number"
					)
			where		exists (
						select			1
							from		"vote_adjustments" "j"
							where		"j"."poll_id" = "o"."poll_id"
					)
			group by	1
	),
	"deleted" ("poll_id") as (
		delete from		"statistics"."polls" "s"
			using		"vote_adjustments" "j"
			where		"j"."poll_id" = "s"."poll_id"
				and	"s"."votes" + "j"."adjustment" = 0
			returning	"s"."poll_id"
	),
	"updated" ("poll_id") as (
		update			"statistics"."polls" "s"
			set		"votes" = "s"."votes" + "j"."adjustment",
					"voters" = "c"."voters"
			from		"vote_adjustments" "j"
			join		"new_voter_counts" "c"
				using	("poll_id")
			where		"j"."poll_id" = "s"."poll_id"
				and	not exists (
						select			1
							from		"deleted" "d"
							where		"d"."poll_id" = "j"."poll_id"
					)
			returning	"s"."poll_id"
	)
	insert into		"statistics"."polls" as "s" (
					"poll_id",
					"votes",
					"voters"
				)
	select			"j"."poll_id",
				"j"."adjustment",
				"c"."voters"
		from		"vote_adjustments" "j"
		join		"new_voter_counts" "c"
			using	("poll_id")
		where		not exists (
					select			1
						from		"updated" "u"
						where		"u"."poll_id" = "j"."poll_id"
				)
			and	not exists (
					select			1
						from		"deleted" "d"
						where		"d"."poll_id" = "j"."poll_id"
				)
		on conflict	("poll_id")
			do	update
			set	"votes" = "s"."votes" + "excluded"."votes";
	drop table		"pg_temp"."poll_vote_adjustments";
end
$$;


--
-- Name: process_reply_status_controversial_scores_queue(); Type: PROCEDURE; Schema: elwood_api; Owner: -
--

CREATE PROCEDURE elwood_api.process_reply_status_controversial_scores_queue()
    LANGUAGE plpgsql
    AS $$
begin
	create temp table	"reply_status_controversial_scores_to_recalculate" (
					"status_id"		int8		not null,
					primary key		("status_id")
				);
	with "batch" ("ctid") as (
		select			"ctid"
			from		"queues"."reply_status_controversial_scores"
			order by	"priority" desc
			limit		10000
	),
	"queue" ("status_id") as (
		delete from		"queues"."reply_status_controversial_scores" "q"
			where		exists (
						select			1
							from		"batch" "b"
							where		"b"."ctid" = "q"."ctid"
					)
			returning	"status_id"
	)
	insert into		"pg_temp"."reply_status_controversial_scores_to_recalculate" ("status_id")
	select			"q"."status_id"
		from		"queue" "q"
		where		exists (
					select			1
						from		"public"."statuses" "s"
						where		"s"."id" = "q"."status_id"
				)
		group by	1;
	analyze			"pg_temp"."reply_status_controversial_scores_to_recalculate";
	with "scores" (
		"status_id",
		"reply_to_status_id",
		"score"
	) as (
		select			"s"."id",
					"s"."in_reply_to_id",
					(
						(
							coalesce ("r"."repliers_count", 0)
						/	coalesce ("f"."favourites_count", 1)
						+	coalesce ("b"."rebloggers_count", 0)
						)
					*
						"date_part" (
							'epoch',
							(
								"s"."created_at"
							-	"p"."created_at"
							)
						)
					)
			from		"public"."statuses" "s"
			join		"public"."statuses" "p"
				on	"p"."id" = "s"."in_reply_to_id"
			left join	"statistics"."status_favourites" "f"
				on	"f"."status_id" = "s"."id"
			left join	"statistics"."status_reblogs" "b"
				on	"b"."status_id" = "s"."id"
			left join	"statistics"."status_replies" "r"
				on	"r"."status_id" = "s"."id"
			where		exists (
						select			1
							from		"pg_temp"."reply_status_controversial_scores_to_recalculate" "x"
							where		"x"."status_id" = "s"."id"
					)
	),
	"updated" ("status_id") as (
		update			"statistics"."reply_status_controversial_scores" "s"
			set		"reply_to_status_id" = "c"."reply_to_status_id",
					"score" = "c"."score"
			from		"scores" "c"
			where		"c"."status_id" = "s"."status_id"
			returning	"s"."status_id"
	)
	insert into		"statistics"."reply_status_controversial_scores" as "s" (
					"status_id",
					"reply_to_status_id",
					"score"
				)
	select			"c"."status_id",
				"c"."reply_to_status_id",
				"c"."score"
		from		"scores" "c"
		where		not exists (
					select			1
						from		"updated" "u"
						where		"u"."status_id" = "c"."status_id"
				)
		on conflict	("status_id")
			do	update
			set	"reply_to_status_id" = "excluded"."reply_to_status_id",
				"score" = "excluded"."score";
	drop table		"pg_temp"."reply_status_controversial_scores_to_recalculate";
end
$$;


--
-- Name: process_reply_status_trending_scores_queue(); Type: PROCEDURE; Schema: elwood_api; Owner: -
--

CREATE PROCEDURE elwood_api.process_reply_status_trending_scores_queue()
    LANGUAGE plpgsql
    AS $$
begin
	create temp table	"reply_status_trending_scores_to_recalculate" (
					"status_id"		int8		not null,
					primary key		("status_id")
				);
	with "batch" ("ctid") as (
		select			"ctid"
			from		"queues"."reply_status_trending_scores"
			order by	"priority" desc
			limit		10000
	),
	"queue" ("status_id") as (
		delete from		"queues"."reply_status_trending_scores" "q"
			where		exists (
						select			1
							from		"batch" "b"
							where		"b"."ctid" = "q"."ctid"
					)
			returning	"status_id"
	)
	insert into		"pg_temp"."reply_status_trending_scores_to_recalculate" ("status_id")
	select			"q"."status_id"
		from		"queue" "q"
		where		exists (
					select			1
						from		"public"."statuses" "s"
						where		"s"."id" = "q"."status_id"
				)
		group by	1;
	analyze			"pg_temp"."reply_status_trending_scores_to_recalculate";
	with "scores" (
		"status_id",
		"reply_to_status_id",
		"score"
	) as (
		select			"s"."id",
					"s"."in_reply_to_id",
					(
						coalesce ("e"."engagers_count", 0)
					*	"date_part" (
							'epoch',
							(
								"s"."created_at"
							-	"p"."created_at"
							)
						)
					)
			from		"public"."statuses" "s"
			join		"public"."statuses" "p"
				on	"p"."id" = "s"."in_reply_to_id"
			left join	"statistics"."status_engagement" "e"
				on	"e"."status_id" = "s"."id"
			where		exists (
						select			1
							from		"pg_temp"."reply_status_trending_scores_to_recalculate" "x"
							where		"x"."status_id" = "s"."id"
					)
	),
	"updated" ("status_id") as (
		update			"statistics"."reply_status_trending_scores" "s"
			set		"reply_to_status_id" = "c"."reply_to_status_id",
					"score" = "c"."score"
			from		"scores" "c"
			where		"c"."status_id" = "s"."status_id"
			returning	"s"."status_id"
	)
	insert into		"statistics"."reply_status_trending_scores" as "s" (
					"status_id",
					"reply_to_status_id",
					"score"
				)
	select			"c"."status_id",
				"c"."reply_to_status_id",
				"c"."score"
		from		"scores" "c"
		where		not exists (
					select			1
						from		"updated" "u"
						where		"u"."status_id" = "c"."status_id"
				)
		on conflict	("status_id")
			do	update
			set	"reply_to_status_id" = "excluded"."reply_to_status_id",
				"score" = "excluded"."score";
	drop table		"pg_temp"."reply_status_trending_scores_to_recalculate";
end
$$;


--
-- Name: process_status_engagement_statistics_queue(); Type: PROCEDURE; Schema: elwood_api; Owner: -
--

CREATE PROCEDURE elwood_api.process_status_engagement_statistics_queue()
    LANGUAGE plpgsql
    AS $$
begin
	create temp table	"status_engagement_statistics_to_recalculate" (
					"status_id"		int8		not null,
					primary key		("status_id")
				);
	with "batch" ("ctid") as (
		select			"ctid"
			from		"queues"."status_engagement_statistics"
			order by	"priority" desc
			limit		10000
	),
	"queue" ("status_id") as (
		delete from		"queues"."status_engagement_statistics" "q"
			where		exists (
						select			1
							from		"batch" "b"
							where		"b"."ctid" = "q"."ctid"
					)
			returning	"status_id"
	)
	insert into		"pg_temp"."status_engagement_statistics_to_recalculate" ("status_id")
	select			"q"."status_id"
		from		"queue" "q"
		where		exists (
					select			1
						from		"public"."statuses" "s"
						where		"s"."id" = "q"."status_id"
				)
		group by	1;
	analyze			"pg_temp"."status_engagement_statistics_to_recalculate";
	with "counts" (
		"status_id",
		"engagers_count"
	) as (
		select			"s"."status_id",
					(
						select			count (distinct "account_id")
							from		(
										select			"account_id"
											from		"public"."statuses"
											where		"deleted_at" is null
												and	"in_reply_to_id" = "s"."status_id"
										union all
										select			"account_id"
											from		"public"."statuses"
											where		"deleted_at" is null
												and	"reblog_of_id" = "s"."status_id"
										union all
										select			"account_id"
											from		"public"."statuses"
											where		"deleted_at" is null
												and	"quote_id" = "s"."status_id"
										union all
										select			"account_id"
											from		"public"."favourites"
											where		"status_id" = "s"."status_id"
									) "x"
					)
			from		"status_engagement_statistics_to_recalculate" "s"
	),
	"deleted" ("status_id") as (
		delete from		"statistics"."status_engagement" "s"
			using		"counts" "e"
			where		"e"."status_id" = "s"."status_id"
				and	"s"."engagers_count" = 0
			returning	"s"."status_id"
	),
	"updated" ("status_id") as (
		update			"statistics"."status_engagement" "s"
			set		"engagers_count" = "e"."engagers_count"
			from		"counts" "e"
			where		"e"."status_id" = "s"."status_id"
				and	not exists (
						select			1
							from		"deleted"
							where		"status_id" = "e"."status_id"
					)
			returning	"s"."status_id"
	)
	insert into		"statistics"."status_engagement" as "s" (
					"status_id",
					"engagers_count"
				)
	select			"e"."status_id",
				"e"."engagers_count"
		from		"counts" "e"
		where		not exists (
					select			1
						from		"updated"
						where		"status_id" = "e"."status_id"
				)
			and	not exists (
					select			1
						from		"deleted"
						where		"status_id" = "e"."status_id"
				)
			and	"e"."engagers_count" > 0
		on conflict	("status_id")
			do	update
			set	"engagers_count" = "excluded"."engagers_count";
	drop table		"pg_temp"."status_engagement_statistics_to_recalculate";
end
$$;


--
-- Name: process_status_favourite_statistics_queue(); Type: PROCEDURE; Schema: elwood_api; Owner: -
--

CREATE PROCEDURE elwood_api.process_status_favourite_statistics_queue()
    LANGUAGE plpgsql
    AS $$
begin
	create temp table	"status_favourite_statistics_adjustments" (
					"status_id"		int8		not null,
					"adjustment"		int4		not null,
					primary key		("status_id")
				);
	with "batch" ("ctid") as (
		select			"ctid"
			from		"queues"."status_favourite_statistics"
			order by	"priority" desc
			limit		10000
	),
	"queue" (
		"status_id",
		"adjustment"
	) as (
		delete from		"queues"."status_favourite_statistics" "q"
			where		exists (
						select			1
							from		"batch" "b"
							where		"b"."ctid" = "q"."ctid"
					)
			returning	"q"."status_id",
					"q"."adjustment"
	)
	insert into		"pg_temp"."status_favourite_statistics_adjustments" (
					"status_id",
					"adjustment"
				)
	select			"q"."status_id",
				sum ("q"."adjustment")
		from		"queue" "q"
		where		exists (
					select			1
						from		"public"."statuses" "x"
						where		"x"."id" = "q"."status_id"
				)
		group by	1;
	analyze			"pg_temp"."status_favourite_statistics_adjustments";
	with "deleted" ("status_id") as (
		delete from		"statistics"."status_favourites" "s"
			using		"pg_temp"."status_favourite_statistics_adjustments" "j"
			where		"j"."status_id" = "s"."status_id"
				and	"s"."favourites_count" + "j"."adjustment" = 0
			returning	"s"."status_id"
	),
	"updated" ("status_id") as (
		update			"statistics"."status_favourites" "s"
			set		"favourites_count" = "s"."favourites_count" + "j"."adjustment"
			from		"pg_temp"."status_favourite_statistics_adjustments" "j"
			where		"j"."status_id" = "s"."status_id"
				and	not exists (
						select			1
							from		"deleted" "x"
							where		"x"."status_id" = "j"."status_id"
					)
			returning	"s"."status_id"
	)
	insert into		"statistics"."status_favourites" as "s" (
					"status_id",
					"favourites_count"
				)
	select			"j"."status_id",
				"j"."adjustment"
		from		"pg_temp"."status_favourite_statistics_adjustments" "j"
		where		not exists (
					select			1
						from		"updated" "x"
						where		"x"."status_id" = "j"."status_id"
				)
			and	not exists (
					select			1
						from		"deleted" "x"
						where		"x"."status_id" = "j"."status_id"
				)
			and	"j"."adjustment" <> 0
		on conflict	("status_id")
			do	update
			set	"favourites_count" = "s"."favourites_count" + "excluded"."favourites_count";
	drop table		"status_favourite_statistics_adjustments";
end
$$;


--
-- Name: process_status_reblog_statistics_queue(); Type: PROCEDURE; Schema: elwood_api; Owner: -
--

CREATE PROCEDURE elwood_api.process_status_reblog_statistics_queue()
    LANGUAGE plpgsql
    AS $$
begin
	create temp table	"status_reblog_statistics_to_recalculate" (
					"status_id"		int8		not null,
					primary key		("status_id")
				);
	with "batch" ("ctid") as (
		select			"ctid"
			from		"queues"."status_reblog_statistics"
			order by	"priority" desc
			limit		10000
	),
	"queue" ("status_id") as (
		delete from		"queues"."status_reblog_statistics" "q"
			where		exists (
						select			1
							from		"batch" "b"
							where		"b"."ctid" = "q"."ctid"
					)
			returning	"q"."status_id"
	)
	insert into		"pg_temp"."status_reblog_statistics_to_recalculate" ("status_id")
	select			"q"."status_id"
		from		"queue" "q"
		where		exists (
					select			1
						from		"public"."statuses" "x"
						where		"x"."id" = "q"."status_id"
				)
		group by	1;
	analyze			"pg_temp"."status_reblog_statistics_to_recalculate";
	with "reblogs" (
		"status_id",
		"account_id"
	) as (
		select			"s"."reblog_of_id",
					"s"."account_id"
			from		"public"."statuses" "s"
			where		"s"."deleted_at" is null
				and	exists (
						select			1
							from		"pg_temp"."status_reblog_statistics_to_recalculate" "x"
							where		"x"."status_id" = "s"."reblog_of_id"
					)
		union all
		select			"s"."quote_id",
					"s"."account_id"
			from		"public"."statuses" "s"
			where		"s"."deleted_at" is null
				and	exists (
						select			1
							from		"pg_temp"."status_reblog_statistics_to_recalculate" "x"
							where		"x"."status_id" = "s"."quote_id"
					)
	),
	"counts" (
		"status_id",
		"reblogs_count",
		"rebloggers_count"
	) as (
		select			"t"."status_id",
					count ("r".*),
					count (distinct "r"."account_id")
			from		"pg_temp"."status_reblog_statistics_to_recalculate" "t"
			left join	"reblogs" "r"
				using	("status_id")
			group by	1
	),
	"deleted" ("status_id") as (
		delete from		"statistics"."status_reblogs" "s"
			using		"counts" "c"
			where		"c"."status_id" = "s"."status_id"
				and	"c"."reblogs_count" = 0
			returning	"s"."status_id"
	),
	"updated" ("status_id") as (
		update			"statistics"."status_reblogs" "s"
			set		"reblogs_count" = "c"."reblogs_count",
					"rebloggers_count" = "c"."rebloggers_count"
			from		"counts" "c"
			where		"c"."status_id" = "s"."status_id"
				and	not exists (
						select			1
							from		"deleted" "x"
							where		"x"."status_id" = "c"."status_id"
					)
			returning	"s"."status_id"
	)
	insert into		"statistics"."status_reblogs" as "s" (
					"status_id",
					"reblogs_count",
					"rebloggers_count"
				)
	select			"c"."status_id",
				"c"."reblogs_count",
				"c"."rebloggers_count"
		from		"counts" "c"
		where		not exists (
					select			1
						from		"updated" "x"
						where		"x"."status_id" = "c"."status_id"
				)
			and	not exists (
					select			1
						from		"deleted" "x"
						where		"x"."status_id" = "c"."status_id"
				)
			and	"c"."reblogs_count" <> 0
		on conflict	("status_id")
			do	update
			set	"reblogs_count" = "excluded"."reblogs_count",
				"rebloggers_count" = "excluded"."rebloggers_count";
	drop table		"pg_temp"."status_reblog_statistics_to_recalculate";
end
$$;


--
-- Name: process_status_reply_scores_queue(); Type: PROCEDURE; Schema: elwood_api; Owner: -
--

CREATE PROCEDURE elwood_api.process_status_reply_scores_queue()
    LANGUAGE plpgsql
    AS $$
begin
	create temp table	"statuses_to_recalculate" (
					"status_id"		int8		not null,
					primary key		("status_id")
				);
	with "batch" ("ctid") as (
		select			"ctid"
			from		"queues"."status_reply_scores"
			order by	1
			limit		250000
	),
	"queue" ("status_id") as (
		delete from		"queues"."status_reply_scores" "q"
			where		exists (
						select			1
							from		"batch" "b"
							where		"b"."ctid" = "q"."ctid"
					)
			returning	"status_id"
	)
	insert into		"pg_temp"."statuses_to_recalculate" ("status_id")
	select			distinct "q"."status_id"
		from		"queue" "q"
		where		exists (
					select			1
						from		"public"."statuses" "s"
						where		"s"."id" = "q"."status_id"
				);
	analyze			"pg_temp"."statuses_to_recalculate";
	with "status_reply_scores" (
		"status_id",
		"reply_to_status_id",
		"trending_score",
		"controversial_score"
	) as (
		select			"s"."id",
					"s"."in_reply_to_id",
					(
						(
							coalesce ("f"."favourites_count", 0)
						+	(
								coalesce ("b"."reblogs_count", 0)
							*	2
							)
						+	(
								coalesce ("r"."repliers_count", 0)
							*	2
							)
						)
					*	greatest (
							"date_part" (
								'epoch',
								(
									"s"."created_at"
								-	"p"."created_at"
								)
							),
							1
						)
					),
					(
						(
							coalesce ("r"."repliers_count", 0)
						/	coalesce ("f"."favourites_count", 1)
						+	coalesce ("b"."reblogs_count", 0)
						)
					*	greatest (
							"date_part" (
								'epoch',
								(
									"s"."created_at"
								-	"p"."created_at"
								)
							),
							1
						)
					)
			from		"public"."statuses" "s"
			join		"public"."statuses" "p"
				on	"p"."id" = "s"."in_reply_to_id"
			left join	"statistics"."status_favourites" "f"
				on	"f"."status_id" = "s"."id"
			left join	"statistics"."status_reblogs" "b"
				on	"b"."status_id" = "s"."id"
			left join	"statistics"."status_replies" "r"
				on	"r"."status_id" = "s"."id"
			where		exists (
						select			1
							from		"pg_temp"."statuses_to_recalculate" "x"
							where		"x"."status_id" = "s"."id"
					)
	),
	"updated" ("status_id") as (
		update			"statistics"."status_reply_scores" "a"
			set		"reply_to_status_id" = "s"."reply_to_status_id",
					"trending_score" = "s"."trending_score",
					"controversial_score" = "s"."controversial_score"
			from		"status_reply_scores" "s"
			where		"s"."status_id" = "a"."status_id"
			returning	"a"."status_id"
	)
	insert into		"statistics"."status_reply_scores" as "a" (
					"status_id",
					"reply_to_status_id",
					"trending_score",
					"controversial_score"
				)
	select			"s"."status_id",
				"s"."reply_to_status_id",
				"s"."trending_score",
				"s"."controversial_score"
		from		"status_reply_scores" "s"
		where		not exists (
					select			1
						from		"updated" "u"
						where		"u"."status_id" = "s"."status_id"
				)
		on conflict	("status_id")
			do	update
			set	"trending_score" = "excluded"."trending_score",
				"controversial_score" = "excluded"."controversial_score";
	drop table		"pg_temp"."statuses_to_recalculate";
end
$$;


--
-- Name: process_status_reply_statistics_queue(); Type: PROCEDURE; Schema: elwood_api; Owner: -
--

CREATE PROCEDURE elwood_api.process_status_reply_statistics_queue()
    LANGUAGE plpgsql
    AS $$
begin
	create temp table	"status_reply_statistics_to_recalculate" (
					"status_id"		int8		not null,
					primary key		("status_id")
				);
	with "batch" ("ctid") as (
		select			"ctid"
			from		"queues"."status_reply_statistics"
			order by	"priority" desc
			limit		10000
	),
	"queue" ("status_id") as (
		delete from		"queues"."status_reply_statistics" "q"
			where		exists (
						select			1
							from		"batch" "b"
							where		"b"."ctid" = "q"."ctid"
					)
			returning	"q"."status_id"
	)
	insert into		"pg_temp"."status_reply_statistics_to_recalculate" ("status_id")
	select			"q"."status_id"
		from		"queue" "q"
		where		exists (
					select			1
						from		"public"."statuses" "x"
						where		"x"."id" = "q"."status_id"
				)
		group by	1;
	analyze			"pg_temp"."status_reply_statistics_to_recalculate";
	with "counts" (
		"status_id",
		"replies_count",
		"repliers_count"
	) as (
		select			"t"."status_id",
					count ("s".*),
					count (distinct "s"."account_id")
			from		"pg_temp"."status_reply_statistics_to_recalculate" "t"
			left join	"public"."statuses" "s"
				on	"s"."in_reply_to_id" = "t"."status_id"
				and	"s"."deleted_at" is null
			group by	1
	),
	"deleted" ("status_id") as (
		delete from		"statistics"."status_replies" "s"
			using		"counts" "c"
			where		"c"."status_id" = "s"."status_id"
				and	"c"."replies_count" = 0
			returning	"s"."status_id"
	),
	"updated" ("status_id") as (
		update			"statistics"."status_replies" "s"
			set		"replies_count" = "c"."replies_count",
					"repliers_count" = "c"."repliers_count"
			from		"counts" "c"
			where		"c"."status_id" = "s"."status_id"
				and	not exists (
						select			1
							from		"deleted" "x"
							where		"x"."status_id" = "c"."status_id"
					)
			returning	"s"."status_id"
	)
	insert into		"statistics"."status_replies" as "s" (
					"status_id",
					"replies_count",
					"repliers_count"
				)
	select			"c"."status_id",
				"c"."replies_count",
				"c"."repliers_count"
		from		"counts" "c"
		where		not exists (
					select			1
						from		"updated" "x"
						where		"x"."status_id" = "c"."status_id"
				)
			and	not exists (
					select			1
						from		"deleted" "x"
						where		"x"."status_id" = "c"."status_id"
				)
			and	"c"."replies_count" <> 0
		on conflict	("status_id")
			do	update
			set	"replies_count" = "excluded"."replies_count",
				"repliers_count" = "excluded"."repliers_count";
	drop table		"pg_temp"."status_reply_statistics_to_recalculate";
end
$$;


--
-- Name: refresh_group_tag_use_cache(); Type: PROCEDURE; Schema: elwood_api; Owner: -
--

CREATE PROCEDURE elwood_api.refresh_group_tag_use_cache()
    LANGUAGE sql
    AS $$
refresh materialized view
	concurrently	"cache"."group_tag_uses"
$$;


--
-- Name: refresh_tag_use_cache(); Type: PROCEDURE; Schema: elwood_api; Owner: -
--

CREATE PROCEDURE elwood_api.refresh_tag_use_cache()
    LANGUAGE sql
    AS $$
refresh materialized view
	concurrently	"cache"."tag_uses"
$$;


--
-- Name: city_id(text, text, text); Type: FUNCTION; Schema: geography; Owner: -
--

CREATE FUNCTION geography.city_id(in_city text, in_region_code text, in_country_code text) RETURNS integer
    LANGUAGE sql
    AS $$
select			"r"."region_id"
	from		"geography"."cities" "c"
	join		"geography"."regions" "r"
		using	("region_id")
	join		"geography"."countries" "n"
		using	("country_id")
	where		"c"."name" = "in_city"
		and	"r"."code" = "in_region_code"
		and	"n"."code" = "in_country_code"
$$;


--
-- Name: country_id(text); Type: FUNCTION; Schema: geography; Owner: -
--

CREATE FUNCTION geography.country_id(in_code text) RETURNS smallint
    LANGUAGE sql
    AS $$
select			"country_id"
	from		"geography"."countries"
	where		"code" = "in_code"
$$;


--
-- Name: region_id(text, text); Type: FUNCTION; Schema: geography; Owner: -
--

CREATE FUNCTION geography.region_id(in_region_code text, in_country_code text) RETURNS integer
    LANGUAGE sql
    AS $$
select			"r"."region_id"
	from		"geography"."regions" "r"
	join		"geography"."countries" "c"
		using	("country_id")
	where		"r"."code" = "in_region_code"
		and	"c"."code" = "in_country_code"
$$;


--
-- Name: ancestor_statuses(bigint); Type: FUNCTION; Schema: mastodon_api; Owner: -
--

CREATE FUNCTION mastodon_api.ancestor_statuses(in_status_id bigint) RETURNS SETOF bigint
    LANGUAGE sql
    AS $$
with recursive "search_tree" (
	"id",
	"in_reply_to_id",
	"path"
) as (
select			"id",
			"in_reply_to_id",
			array["id"]
	from		"public"."statuses"
	where		"id" = "in_status_id"
union all
select			"s"."id",
			"s"."in_reply_to_id",
			"t"."path" || "s"."id"
	from		"search_tree" "t"
	join		"public"."statuses" "s"
		on	"s"."id" = "t"."in_reply_to_id"
	where		not "s"."id" = any ("t"."path")
)
select			"id"
	from		"search_tree"
	order by	"path"
	limit		"configuration"."feature_setting_value" (
				'ancestor_statuses',
				'maximum_limit'
			)::int4
$$;


--
-- Name: geography_city_create(text, integer); Type: FUNCTION; Schema: mastodon_api; Owner: -
--

CREATE FUNCTION mastodon_api.geography_city_create(in_city_name text, in_region_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
	"var_city_id"		int4;
begin
	select			"city_id"
		into		"var_city_id"
		from		"geography"."cities"
		where		"name" = "in_city_name"
			and	"region_id" = "in_region_id";
	if not found then
		insert into		"geography"."cities" (
						"name",
						"region_id"
					)
			values		(
						"in_city_name",
						"in_region_id"
					)
			on conflict	(
						"name",
						"region_id"
					)
				do	nothing
			returning	"city_id"
				into	"var_city_id";
	end if;
	return "var_city_id";
end
$$;


--
-- Name: geography_country_create(text, text); Type: FUNCTION; Schema: mastodon_api; Owner: -
--

CREATE FUNCTION mastodon_api.geography_country_create(in_country_code text, in_country_name text) RETURNS smallint
    LANGUAGE plpgsql
    AS $$
declare
	"var_country_id"	int2;
	"var_country_name"	text;
begin
	select			"country_id",
				"name"
		into		"var_country_id",
				"var_country_name"
		from		"geography"."countries"
		where		"code" = "in_country_code";
	if found then
		if "in_country_name" <> "var_country_name" then
			update			"geography"."countries"
				set		"name" = "in_country_name"
				where		"country_id" = "var_country_id";
		end if;
	else
		insert into		"geography"."countries" (
						"code",
						"name"
					)
			values		(
						"in_country_code",
						"in_country_name"
					)
			on conflict	("code")
				do	update
				set	"name" = "excluded"."name"
			returning	"country_id"
				into	"var_country_id";
	end if;
	return "var_country_id";
end
$$;


--
-- Name: geography_region_create(text, text, smallint); Type: FUNCTION; Schema: mastodon_api; Owner: -
--

CREATE FUNCTION mastodon_api.geography_region_create(in_region_code text, in_region_name text, in_country_id smallint) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
	"var_region_id"		int4;
	"var_region_name"	text;
begin
	select			"region_id",
				"name"
		into		"var_region_id",
				"var_region_name"
		from		"geography"."regions"
		where		"code" = "in_region_code"
			and	"country_id" = "in_country_id";
	if found then
		if "in_region_name" <> "var_region_name" then
			update			"geography"."regions"
				set		"name" = "in_region_name"
				where		"region_id" = "var_region_id";
		end if;
	else
		insert into		"geography"."regions" (
						"code",
						"name",
						"country_id"
					)
			values		(
						"in_region_code",
						"in_region_name",
						"in_country_id"
					)
			on conflict	(
						"code",
						"country_id"
					)
				do	update
				set	"name" = "excluded"."name"
			returning	"region_id"
				into	"var_region_id";
	end if;
	return "var_region_id";
end
$$;


--
-- Name: group(bigint); Type: FUNCTION; Schema: mastodon_api; Owner: -
--

CREATE FUNCTION mastodon_api."group"(in_group_id bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
select			"to_jsonb" ("x")
	from		"mastodon_logic"."group" (
				"in_group_id"
			) "x"
$$;


--
-- Name: group_tags(bigint, bigint, smallint, integer); Type: FUNCTION; Schema: mastodon_api; Owner: -
--

CREATE FUNCTION mastodon_api.group_tags(in_account_id bigint, in_group_id bigint, in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
select			coalesce (
				"jsonb_agg" (
					"to_jsonb" ("x")
				),
				'[]'
			)
	from		"mastodon_logic"."group_tags" (
				"in_account_id",
				"in_group_id",
				"in_limit",
				"in_offset"
			) "x"
$$;


--
-- Name: groups(bigint, boolean, text, smallint, integer); Type: FUNCTION; Schema: mastodon_api; Owner: -
--

CREATE FUNCTION mastodon_api.groups(in_account_id bigint, in_pending boolean DEFAULT false, in_search_query text DEFAULT NULL::text, in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
select			coalesce (
				"jsonb_agg" ("x"),
				'[]'
			)
	from		"mastodon_logic"."groups" (
				"in_account_id",
				"in_pending",
				"in_search_query",
				"in_limit",
				"in_offset"
			) "x"
$$;


--
-- Name: groups_with_tag(text, smallint, integer); Type: FUNCTION; Schema: mastodon_api; Owner: -
--

CREATE FUNCTION mastodon_api.groups_with_tag(in_tag_name text, in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
select			coalesce (
				"jsonb_agg" (
					"to_jsonb" ("x")
				),
				'[]'
			)
	from		"mastodon_logic"."groups_with_tag" (
				"in_tag_name",
				"in_limit",
				"in_offset"
			) "x"
$$;


--
-- Name: poll_vote_add(bigint, integer, smallint); Type: PROCEDURE; Schema: mastodon_api; Owner: -
--

CREATE PROCEDURE mastodon_api.poll_vote_add(IN in_account_id bigint, IN in_poll_id integer, IN in_option_number smallint)
    LANGUAGE plpgsql
    AS $$
declare
	"var_multiple_choice"	bool;
begin
	select			"multiple_choice"
		into		"var_multiple_choice"
		from		"polls"."polls"
		where		"poll_id" = "in_poll_id";
	if not "var_multiple_choice" then
		perform			1
			from		"polls"."votes"
			where		"poll_id" = "in_poll_id"
				and	"account_id" = "in_account_id";
		if found then
			raise exception 'Account ID % has already voted for poll ID %!',
				"in_account_id",
				"in_poll_id";
		end if;
	end if;
	insert into		"polls"."votes" (
					"poll_id",
					"option_number",
					"account_id"
				)
		values		(
					"in_poll_id",
					"in_option_number",
					"in_account_id"
				)
		on		conflict
			do	nothing;
end
$$;


--
-- Name: poll_vote_remove(bigint, integer, smallint); Type: PROCEDURE; Schema: mastodon_api; Owner: -
--

CREATE PROCEDURE mastodon_api.poll_vote_remove(IN in_account_id bigint, IN in_poll_id integer, IN in_option_number smallint)
    LANGUAGE sql
    AS $$
delete from		"polls"."votes"
	where		"poll_id" = "in_poll_id"
		and	"option_number" = "in_option_number"
		and	"account_id" = "in_account_id"
$$;


--
-- Name: popular_group_tags(smallint, integer); Type: FUNCTION; Schema: mastodon_api; Owner: -
--

CREATE FUNCTION mastodon_api.popular_group_tags(in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
select			coalesce (
				"jsonb_agg" (
					"to_jsonb" ("x")
				),
				'[]'
			)
	from		"mastodon_logic"."popular_group_tags" (
				"in_limit",
				"in_offset"
			) "x"
$$;


--
-- Name: recommended_follows(bigint, smallint, integer); Type: FUNCTION; Schema: mastodon_api; Owner: -
--

CREATE FUNCTION mastodon_api.recommended_follows(in_account_id bigint, in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS mastodon_api.ids_and_total_results
    LANGUAGE sql STABLE
    AS $$
with "data" ("target_account_id") as (
	select			"unnest" ("target_account_ids")
		from		"recommendations"."follows"
		where		"account_id" = "in_account_id"
)
select			"array_agg" ("d"."target_account_id"),
			"count" ("d"."target_account_id")
	from		"data" "d"
	join		"public"."accounts" "a"
		on	"a"."id" = "d"."target_account_id"
	where		"a"."suspended_at" is null
		and	not exists (
				select			1
					from		"public"."blocks" "b"
					where		"b"."target_account_id" = "in_account_id"
						and	"b"."account_id" = "d"."target_account_id"
			)
		and	not exists (
				select			1
					from		"public"."blocks" "b"
					where		"b"."account_id" = "in_account_id"
						and	"b"."target_account_id" = "d"."target_account_id"
			)
		and	not exists (
				select			1
					from		"public"."mutes" "m"
					where		"m"."account_id" = "in_account_id"
						and	"m"."target_account_id" = "d"."target_account_id"
			)
		and	not exists (
				select			1
					from		"public"."follows" "f"
					where		"f"."account_id" = "in_account_id"
						and	"f"."target_account_id" = "d"."target_account_id"
			)
	limit		"in_limit"
		offset	"in_offset"
$$;


--
-- Name: recommended_statuses(bigint, smallint, integer); Type: FUNCTION; Schema: mastodon_api; Owner: -
--

CREATE FUNCTION mastodon_api.recommended_statuses(in_account_id bigint, in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS mastodon_api.ids_and_total_results
    LANGUAGE sql STABLE
    AS $$
with "data" ("status_id") as (
	select			"unnest" ("status_ids")
		from		"recommendations"."statuses"
		where		"account_id" = "in_account_id"
)
select			"array_agg" ("d"."status_id"),
			"count" ("d"."status_id")
	from		"data" "d"
	join		"public"."statuses" "s"
		on	"s"."id" = "d"."status_id"
	join		"public"."accounts" "a"
		on	"a"."id" = "s"."account_id"
	where		"s"."deleted_at" is null
		and	"a"."suspended_at" is null
		and	not exists (
				select			1
					from		"public"."blocks" "b"
					where		"b"."target_account_id" = "in_account_id"
						and	"b"."account_id" = "s"."account_id"
			)
		and	not exists (
				select			1
					from		"public"."blocks" "b"
					where		"b"."account_id" = "in_account_id"
						and	"b"."target_account_id" = "s"."account_id"
			)
		and	not exists (
				select			1
					from		"public"."mutes" "m"
					where		"m"."account_id" = "in_account_id"
						and	"m"."target_account_id" = "s"."account_id"
			)
		and	not exists (
				select			1
					from		"public"."follows" "f"
					where		"f"."account_id" = "in_account_id"
						and	"f"."target_account_id" = "s"."account_id"
			)
	limit		"in_limit"
		offset	"in_offset"
$$;


--
-- Name: save_follow_recommendations(bigint, bigint[]); Type: PROCEDURE; Schema: mastodon_api; Owner: -
--

CREATE PROCEDURE mastodon_api.save_follow_recommendations(IN in_account_id bigint, IN in_target_account_ids bigint[])
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"recommendations"."follows" (
					"account_id",
					"target_account_ids"
				)
		values		(
					"in_account_id",
					"in_target_account_ids"
				)
		on conflict	("account_id")
			do	update
			set	"target_account_ids" = "in_target_account_ids";
end
$$;


--
-- Name: save_status_recommendations(bigint, bigint[]); Type: PROCEDURE; Schema: mastodon_api; Owner: -
--

CREATE PROCEDURE mastodon_api.save_status_recommendations(IN in_account_id bigint, IN in_status_ids bigint[])
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"recommendations"."statuses" (
					"account_id",
					"status_ids"
				)
		values		(
					"in_account_id",
					"in_status_ids"
				)
		on conflict	("account_id")
			do	update
			set	"status_ids" = "in_status_ids";
end
$$;


--
-- Name: search_tags(text, smallint, integer); Type: FUNCTION; Schema: mastodon_api; Owner: -
--

CREATE FUNCTION mastodon_api.search_tags(in_search_query text, in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
select			"jsonb_agg" (
				"to_jsonb" ("x")
			)
	from		"mastodon_logic"."search_tags" (
				"in_search_query",
				"in_limit",
				"in_offset"
			) "x"
$$;


--
-- Name: status_poll(bigint, bigint); Type: FUNCTION; Schema: mastodon_api; Owner: -
--

CREATE FUNCTION mastodon_api.status_poll(in_account_id bigint, in_status_id bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
select			"to_jsonb" ("x")
	from		"mastodon_logic"."status_poll" (
				"in_account_id",
				"in_status_id"
			) "x"
$$;


--
-- Name: status_poll_add(bigint, timestamp without time zone, boolean, text[]); Type: PROCEDURE; Schema: mastodon_api; Owner: -
--

CREATE PROCEDURE mastodon_api.status_poll_add(IN in_status_id bigint, IN in_expires_at timestamp without time zone, IN in_multiple_choice boolean, IN in_options text[])
    LANGUAGE plpgsql
    AS $$
declare
	"var_poll_id"		int4;
begin
	insert into		"polls"."polls" (
					"expires_at",
					"multiple_choice"
				)
		values		(
					"in_expires_at",
					"in_multiple_choice"
				)
		returning	"poll_id"
			into	"var_poll_id";
	insert into		"polls"."options" (
					"poll_id",
					"option_number",
					"text"
				)
	select			"var_poll_id",
				"option_number" - 1,
				"text"
		from		"unnest" ("in_options") with ordinality "u" (
					"text",
					"option_number"
				);
	insert into		"polls"."status_polls" (
					"status_id",
					"poll_id"
				)
		values		(
					"in_status_id",
					"var_poll_id"
				);
end
$$;


--
-- Name: status_polls(bigint, bigint[]); Type: FUNCTION; Schema: mastodon_api; Owner: -
--

CREATE FUNCTION mastodon_api.status_polls(in_account_id bigint, in_status_ids bigint[]) RETURNS SETOF mastodon_logic.status_id_and_poll_json
    LANGUAGE sql STABLE
    AS $$
select			"x"."status_id",
			"to_jsonb" (
				(
					"p"."poll_id",
					"mastodon_logic"."format_timestamp" ("p"."expires_at"),
					"p"."expires_at" < current_timestamp,
					"p"."multiple_choice",
					coalesce (
						"s"."votes",
						0
					),
					coalesce (
						"s"."voters",
						0
					),
					exists (
						select			1
							from		"polls"."votes" "v"
							where		"v"."poll_id" = "p"."poll_id"
								and	"v"."account_id" = "in_account_id"
					),
					(
						select			"array_agg" (
										"option_number"
										order by "option_number"
									)
							from		"polls"."votes" "v"
							where		"v"."poll_id" = "p"."poll_id"
								and	"v"."account_id" = "in_account_id"
					),
					(
						select			"array_agg" ("x")
							from		"mastodon_logic"."poll_options" ("p"."poll_id") "x"
					)
				)::"mastodon_logic"."poll"
			)
	from		"polls"."polls" "p"
	join		"polls"."status_polls" "x"
		using	("poll_id")
	left join	"statistics"."polls" "s"
		using	("poll_id")
	where		"x"."status_id" = any ("in_status_ids")
$$;


--
-- Name: status_replies(bigint, bigint, mastodon_logic.status_reply_sort_order, smallint, integer); Type: FUNCTION; Schema: mastodon_api; Owner: -
--

CREATE FUNCTION mastodon_api.status_replies(in_account_id bigint, in_status_id bigint, in_sort_order mastodon_logic.status_reply_sort_order DEFAULT 'trending'::mastodon_logic.status_reply_sort_order, in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS SETOF bigint
    LANGUAGE sql STABLE
    AS $$
select			"mastodon_logic"."status_replies" (
				"in_account_id",
				"in_status_id",
				"in_sort_order",
				"in_limit",
				"in_offset"
			)
$$;


--
-- Name: trending_group_excluded_group_add(bigint); Type: PROCEDURE; Schema: mastodon_api; Owner: -
--

CREATE PROCEDURE mastodon_api.trending_group_excluded_group_add(IN in_group_id bigint)
    LANGUAGE sql
    AS $$
insert into		"trending_groups"."excluded_groups" ("group_id")
	values		("in_group_id")
	on conflict	("group_id")
		do	nothing
$$;


--
-- Name: trending_group_excluded_group_remove(bigint); Type: PROCEDURE; Schema: mastodon_api; Owner: -
--

CREATE PROCEDURE mastodon_api.trending_group_excluded_group_remove(IN in_group_id bigint)
    LANGUAGE sql
    AS $$
delete from		"trending_groups"."excluded_groups"
	where		"group_id" = "in_group_id"
$$;


--
-- Name: trending_group_excluded_groups(smallint, integer); Type: FUNCTION; Schema: mastodon_api; Owner: -
--

CREATE FUNCTION mastodon_api.trending_group_excluded_groups(in_limit smallint DEFAULT 20, in_page integer DEFAULT 1) RETURNS SETOF mastodon_api.json_and_total_results
    LANGUAGE sql STABLE
    AS $$
with "groups" (
	"group_id",
	"display_name",
	"created_at",
	"owner_account_id",
	"note",
	"avatar_file_name",
	"avatar_content_type",
	"header_file_name",
	"header_content_type",
	"statuses_visibility",
	"discoverable",
	"locked",
	"slug",
	"deleted_at"
) as (
	select			"g"."id",
				"g"."display_name",
				"g"."created_at",
				"g"."owner_account_id",
				"g"."note",
				"g"."avatar_file_name",
				"g"."avatar_content_type",
				"g"."header_file_name",
				"g"."header_content_type",
				"g"."statuses_visibility",
				"g"."discoverable",
				"g"."locked",
				"g"."slug",
				"g"."deleted_at"
		from		"public"."groups" "g"
		where		exists (
					select			1
						from		"trending_groups"."excluded_groups" "x"
						where		"x"."group_id" = "g"."id"
				)
),
"results" ("data") as (
	select			row (
					"g"."group_id",
					"g"."display_name",
					"mastodon_logic"."format_timestamp" ("g"."created_at"),
					row ("g"."owner_account_id")::"mastodon_logic"."group_owner",
					"mastodon_logic"."html_content" ("g"."note"),
					"mastodon_logic"."image_url" (
						'groups',
						'avatars',
						"g"."group_id",
						"g"."avatar_file_name"
					),
					"mastodon_logic"."image_static_url" (
						'groups',
						'avatars',
						"g"."group_id",
						"g"."avatar_file_name",
						"g"."avatar_content_type"
					),
					"mastodon_logic"."image_url" (
						'groups',
						'headers',
						"g"."group_id",
						"g"."header_file_name"
					),
					"mastodon_logic"."image_static_url" (
						'groups',
						'headers',
						"g"."group_id",
						"g"."header_file_name",
						"g"."header_content_type"
					),
					"g"."statuses_visibility",
					true,
					null,
					"g"."discoverable",
					"g"."locked",
					"s"."members_count",
					coalesce (
						(
						select			"array_agg" ("x")
							from		"mastodon_logic"."group_tags_simple" ("g"."group_id") "x"
						),
						array[]::"mastodon_logic"."tag_simple"[]
					),
					"g"."slug",
					"mastodon_logic"."group_url" ("g"."slug"),
					"mastodon_logic"."format_timestamp" ("g"."deleted_at"),
					row ("g"."note")::"mastodon_logic"."group_source"
				)::"mastodon_logic"."group"
		from		"groups" "g"
		join		"public"."group_stats" "s"
			using	("group_id")
		where		exists (
					select			1
						from		"trending_groups"."excluded_groups" "x"
						where		"x"."group_id" = "g"."group_id"
				)
		order by	"g"."slug"
		limit		"in_limit"
			offset	(
					(
						"in_page"
					*	"in_limit"
					)
				-	"in_limit"
				)
)
select			coalesce (
				"jsonb_agg" ("r"."data"),
				'[]'
			),
			(
				select			count (1)
					from		"groups"
			)
	from		"results" "r"
$$;


--
-- Name: trending_groups(bigint, smallint, integer); Type: FUNCTION; Schema: mastodon_api; Owner: -
--

CREATE FUNCTION mastodon_api.trending_groups(in_account_id bigint DEFAULT NULL::bigint, in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
select			coalesce (
				"jsonb_agg" (
					"to_jsonb" ("x")
				),
				'[]'
			)
	from		"mastodon_logic"."trending_groups" (
				"in_account_id",
				"in_limit",
				"in_offset"
			) "x"
$$;


--
-- Name: trending_tags(smallint, smallint); Type: FUNCTION; Schema: mastodon_api; Owner: -
--

CREATE FUNCTION mastodon_api.trending_tags(in_limit smallint DEFAULT 20, in_offset smallint DEFAULT 0) RETURNS jsonb
    LANGUAGE sql
    AS $$
with "trending_tags" (
	"tag_statistics"
) as (
	select			"tag_statistics"
		from		"trending_tags"."trending_tags"
		order by	"sort_order"
		limit		"in_limit"
			offset	"in_offset"
)
select			"jsonb_agg" (
				"to_jsonb" ("tag_statistics")
			)
	from		"trending_tags" "t"
$$;


--
-- Name: update_legacy_status_favourite_statistic(bigint, bigint); Type: PROCEDURE; Schema: mastodon_api; Owner: -
--

CREATE PROCEDURE mastodon_api.update_legacy_status_favourite_statistic(IN in_status_id bigint, IN in_favourites_count bigint)
    LANGUAGE plpgsql
    AS $$
begin
	if "configuration"."feature_setting_value" (
		'statistics',
		'legacy_status_favourite_statistic_update_enabled'
	)::bool then
		insert into		"public"."status_stats" (
						"status_id",
						"favourites_count",
						"created_at",
						"updated_at"
					)
			values		(
						"in_status_id",
						"in_favourites_count",
						current_timestamp at time zone 'UTC',
						current_timestamp at time zone 'UTC'
					)
			on conflict	("status_id")
				do	update
				set	"favourites_count" = "in_favourites_count",
					"updated_at" = current_timestamp at time zone 'UTC';
	end if;
end
$$;


--
-- Name: chat_message_expiration_change(bigint, integer, interval); Type: FUNCTION; Schema: mastodon_chats_api; Owner: -
--

CREATE FUNCTION mastodon_chats_api.chat_message_expiration_change(in_account_id bigint, in_chat_id integer, in_message_expiration interval) RETURNS void
    LANGUAGE sql
    AS $$
call			"mastodon_chats_logic"."chat_message_expiration_change" (
				"in_account_id",
				"in_chat_id",
				"in_message_expiration"
			);
$$;


--
-- Name: FUNCTION chat_message_expiration_change(in_account_id bigint, in_chat_id integer, in_message_expiration interval); Type: COMMENT; Schema: mastodon_chats_api; Owner: -
--

COMMENT ON FUNCTION mastodon_chats_api.chat_message_expiration_change(in_account_id bigint, in_chat_id integer, in_message_expiration interval) IS 'Change the message expiration interval for a chat.';


--
-- Name: events(smallint, bigint, integer, smallint, bigint, bigint, boolean, smallint); Type: FUNCTION; Schema: mastodon_chats_api; Owner: -
--

CREATE FUNCTION mastodon_chats_api.events(in_api_version smallint, in_account_id bigint, in_chat_id integer DEFAULT NULL::integer, in_upgrade_from_api_version smallint DEFAULT NULL::smallint, in_greater_than_event_id bigint DEFAULT NULL::bigint, in_less_than_event_id bigint DEFAULT NULL::bigint, in_order_ascending boolean DEFAULT true, in_page_size smallint DEFAULT 20) RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
select			"jsonb_agg" (
				"jsonb_build_object" (
					'event_id',	"event_id"::text,
					'chat_id',	"chat_id"::text,
					'event_type',	"event_type",
					'timestamp',	"timestamp"
				)
			||	coalesce (
					"payload",
					'{}'
				)
			)
	from		"mastodon_chats_logic"."events" (
				"in_api_version",
				"in_account_id",
				"in_chat_id",
				"in_upgrade_from_api_version",
				"in_greater_than_event_id",
				"in_less_than_event_id",
				"in_order_ascending",
				"in_page_size"
			);
$$;


--
-- Name: FUNCTION events(in_api_version smallint, in_account_id bigint, in_chat_id integer, in_upgrade_from_api_version smallint, in_greater_than_event_id bigint, in_less_than_event_id bigint, in_order_ascending boolean, in_page_size smallint); Type: COMMENT; Schema: mastodon_chats_api; Owner: -
--

COMMENT ON FUNCTION mastodon_chats_api.events(in_api_version smallint, in_account_id bigint, in_chat_id integer, in_upgrade_from_api_version smallint, in_greater_than_event_id bigint, in_less_than_event_id bigint, in_order_ascending boolean, in_page_size smallint) IS 'Return chat events for the specified account.';


--
-- Name: message(bigint, integer, bigint); Type: FUNCTION; Schema: mastodon_chats_api; Owner: -
--

CREATE FUNCTION mastodon_chats_api.message(in_account_id bigint, in_chat_id integer, in_message_id bigint) RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
select			"to_jsonb" ("x")
	from		"mastodon_chats_logic"."message" (
				"in_account_id",
				"in_chat_id",
				"in_message_id"
			) "x"
$$;


--
-- Name: FUNCTION message(in_account_id bigint, in_chat_id integer, in_message_id bigint); Type: COMMENT; Schema: mastodon_chats_api; Owner: -
--

COMMENT ON FUNCTION mastodon_chats_api.message(in_account_id bigint, in_chat_id integer, in_message_id bigint) IS 'Return a single message.';


--
-- Name: message_create(bigint, text, uuid, integer, text, bigint[]); Type: FUNCTION; Schema: mastodon_chats_api; Owner: -
--

CREATE FUNCTION mastodon_chats_api.message_create(in_account_id bigint, in_oauth_access_token text, in_idempotency_key uuid, in_chat_id integer, in_content text, in_media_attachment_ids bigint[] DEFAULT NULL::bigint[]) RETURNS jsonb
    LANGUAGE sql
    AS $$
select			"to_jsonb" ("x")
	from		"mastodon_chats_logic"."message_create" (
				"in_account_id",
				"in_oauth_access_token",
				"in_idempotency_key",
				"in_chat_id",
				"in_content",
				"in_media_attachment_ids"
			) "x"
$$;


--
-- Name: FUNCTION message_create(in_account_id bigint, in_oauth_access_token text, in_idempotency_key uuid, in_chat_id integer, in_content text, in_media_attachment_ids bigint[]); Type: COMMENT; Schema: mastodon_chats_api; Owner: -
--

COMMENT ON FUNCTION mastodon_chats_api.message_create(in_account_id bigint, in_oauth_access_token text, in_idempotency_key uuid, in_chat_id integer, in_content text, in_media_attachment_ids bigint[]) IS 'Creates a new chat message.';


--
-- Name: message_delete(bigint, bigint); Type: FUNCTION; Schema: mastodon_chats_api; Owner: -
--

CREATE FUNCTION mastodon_chats_api.message_delete(in_account_id bigint, in_message_id bigint) RETURNS void
    LANGUAGE sql
    AS $$
call			"mastodon_chats_logic"."message_delete" (
				"in_account_id",
				"in_message_id"
			);
$$;


--
-- Name: FUNCTION message_delete(in_account_id bigint, in_message_id bigint); Type: COMMENT; Schema: mastodon_chats_api; Owner: -
--

COMMENT ON FUNCTION mastodon_chats_api.message_delete(in_account_id bigint, in_message_id bigint) IS 'Deletes a chat message if it was created by the specified account.';


--
-- Name: message_hide(bigint, bigint); Type: FUNCTION; Schema: mastodon_chats_api; Owner: -
--

CREATE FUNCTION mastodon_chats_api.message_hide(in_account_id bigint, in_message_id bigint) RETURNS void
    LANGUAGE sql
    AS $$
call			"mastodon_chats_logic"."message_hide" (
				"in_account_id",
				"in_message_id"
			);
$$;


--
-- Name: FUNCTION message_hide(in_account_id bigint, in_message_id bigint); Type: COMMENT; Schema: mastodon_chats_api; Owner: -
--

COMMENT ON FUNCTION mastodon_chats_api.message_hide(in_account_id bigint, in_message_id bigint) IS 'Hides the specified chat message for the specified account.';


--
-- Name: message_modifications(bigint, integer, integer); Type: FUNCTION; Schema: mastodon_chats_api; Owner: -
--

CREATE FUNCTION mastodon_chats_api.message_modifications(in_account_id bigint, in_chat_id integer, in_modified_since integer) RETURNS bigint[]
    LANGUAGE sql STABLE
    AS $$
with "messages" (
	"message_id",
	"modified_at"
) as (
	select			"m"."message_id",
				"h"."created_at"
		from		"chats"."messages" "m"
		join		"chats"."hidden_messages" "h"
			using	("message_id")
		where		"h"."account_id" = "in_account_id"
			and	"m"."chat_id" = "in_chat_id"
			and	"h"."created_at" > "to_timestamp" ("in_modified_since") at time zone 'UTC'
			and	exists (
					select			1
						from		"chats"."members" "b"
						where		"b"."chat_id" = "m"."chat_id"
							and	"b"."account_id" = "h"."account_id"
							and	"b"."active"
				)
	union all
	select			"d"."message_id",
				"d"."deleted_at"
		from		"chats"."deleted_messages" "d"
		where		"d"."chat_id" = "in_chat_id"
			and	"d"."deleted_at" > "to_timestamp" ("in_modified_since") at time zone 'UTC'
			and	exists (
					select			1
						from		"chats"."members" "b"
						where		"b"."chat_id" = "d"."chat_id"
							and	"b"."account_id" = "in_account_id"
							and	"b"."active"
				)
)
select			coalesce (
				"array_agg" ("message_id" order by "modified_at"),
				'{}'
			)
	from		"messages"
$$;


--
-- Name: message_reaction_add(bigint, bigint, text); Type: FUNCTION; Schema: mastodon_chats_api; Owner: -
--

CREATE FUNCTION mastodon_chats_api.message_reaction_add(in_account_id bigint, in_message_id bigint, in_emoji text) RETURNS jsonb
    LANGUAGE sql
    AS $$
call			"mastodon_chats_logic"."message_reaction_add" (
				"in_account_id",
				"in_message_id",
				"in_emoji"
			);
select			"to_jsonb" ("x")
	from		"mastodon_chats_logic"."message" (
				"in_account_id",
				"chats"."message_chat_id" ("in_message_id"),
				"in_message_id"
			) "x"
$$;


--
-- Name: FUNCTION message_reaction_add(in_account_id bigint, in_message_id bigint, in_emoji text); Type: COMMENT; Schema: mastodon_chats_api; Owner: -
--

COMMENT ON FUNCTION mastodon_chats_api.message_reaction_add(in_account_id bigint, in_message_id bigint, in_emoji text) IS 'Add a new emoji reaction to a chat message.  Do nothing if it already exists for specified account.';


--
-- Name: message_reaction_info(bigint, bigint, text); Type: FUNCTION; Schema: mastodon_chats_api; Owner: -
--

CREATE FUNCTION mastodon_chats_api.message_reaction_info(in_account_id bigint, in_message_id bigint, in_emoji text) RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
select			"to_jsonb" ("x")
	from		"mastodon_chats_logic"."message_reaction_info" (
				"in_account_id",
				"in_message_id",
				"in_emoji"
			) "x"
$$;


--
-- Name: FUNCTION message_reaction_info(in_account_id bigint, in_message_id bigint, in_emoji text); Type: COMMENT; Schema: mastodon_chats_api; Owner: -
--

COMMENT ON FUNCTION mastodon_chats_api.message_reaction_info(in_account_id bigint, in_message_id bigint, in_emoji text) IS 'Information about a specific emoji reaction.';


--
-- Name: message_reaction_remove(bigint, bigint, text); Type: FUNCTION; Schema: mastodon_chats_api; Owner: -
--

CREATE FUNCTION mastodon_chats_api.message_reaction_remove(in_account_id bigint, in_message_id bigint, in_emoji text) RETURNS jsonb
    LANGUAGE sql
    AS $$
call			"mastodon_chats_logic"."message_reaction_remove" (
				"in_account_id",
				"in_message_id",
				"in_emoji"
			);
select			"to_jsonb" ("x")
	from		"mastodon_chats_logic"."message" (
				"in_account_id",
				"chats"."message_chat_id" ("in_message_id"),
				"in_message_id"
			) "x"
$$;


--
-- Name: FUNCTION message_reaction_remove(in_account_id bigint, in_message_id bigint, in_emoji text); Type: COMMENT; Schema: mastodon_chats_api; Owner: -
--

COMMENT ON FUNCTION mastodon_chats_api.message_reaction_remove(in_account_id bigint, in_message_id bigint, in_emoji text) IS 'Remove an emoji reaction to a chat message if one exists for specified account.';


--
-- Name: message_unhide(bigint, bigint); Type: FUNCTION; Schema: mastodon_chats_api; Owner: -
--

CREATE FUNCTION mastodon_chats_api.message_unhide(in_account_id bigint, in_message_id bigint) RETURNS void
    LANGUAGE sql
    AS $$
call			"mastodon_chats_logic"."message_unhide" (
				"in_account_id",
				"in_message_id"
			);
$$;


--
-- Name: FUNCTION message_unhide(in_account_id bigint, in_message_id bigint); Type: COMMENT; Schema: mastodon_chats_api; Owner: -
--

COMMENT ON FUNCTION mastodon_chats_api.message_unhide(in_account_id bigint, in_message_id bigint) IS 'Unhides the specified chat message for the specified account.';


--
-- Name: message_with_context(bigint, smallint, smallint); Type: FUNCTION; Schema: mastodon_chats_api; Owner: -
--

CREATE FUNCTION mastodon_chats_api.message_with_context(in_message_id bigint, in_previous_limit smallint, in_next_limit smallint) RETURNS jsonb
    LANGUAGE sql
    AS $$
select			"to_jsonb" ("x")
	from		"mastodon_chats_logic"."message_with_context" (
				"in_message_id",
				"in_previous_limit",
				"in_next_limit"
			) "x"
$$;


--
-- Name: FUNCTION message_with_context(in_message_id bigint, in_previous_limit smallint, in_next_limit smallint); Type: COMMENT; Schema: mastodon_chats_api; Owner: -
--

COMMENT ON FUNCTION mastodon_chats_api.message_with_context(in_message_id bigint, in_previous_limit smallint, in_next_limit smallint) IS 'Returns a given message along with previous and next messages within the same chat, used when messages are reported.';


--
-- Name: messages(bigint, integer, bigint, bigint, boolean, smallint); Type: FUNCTION; Schema: mastodon_chats_api; Owner: -
--

CREATE FUNCTION mastodon_chats_api.messages(in_account_id bigint, in_chat_id integer, in_minimum_message_id bigint DEFAULT NULL::bigint, in_maximum_message_id bigint DEFAULT NULL::bigint, in_order_ascending boolean DEFAULT true, in_page_size smallint DEFAULT 20) RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
select			"jsonb_agg" (
				"to_jsonb" ("x")
			)
	from		"mastodon_chats_logic"."messages" (
				"in_account_id",
				"in_chat_id",
				"in_minimum_message_id",
				"in_maximum_message_id",
				"in_order_ascending",
				"in_page_size"
			) "x"
$$;


--
-- Name: FUNCTION messages(in_account_id bigint, in_chat_id integer, in_minimum_message_id bigint, in_maximum_message_id bigint, in_order_ascending boolean, in_page_size smallint); Type: COMMENT; Schema: mastodon_chats_api; Owner: -
--

COMMENT ON FUNCTION mastodon_chats_api.messages(in_account_id bigint, in_chat_id integer, in_minimum_message_id bigint, in_maximum_message_id bigint, in_order_ascending boolean, in_page_size smallint) IS 'Return paginated messages for an input account and chat.';


--
-- Name: messages_visible(bigint, bigint[]); Type: FUNCTION; Schema: mastodon_chats_api; Owner: -
--

CREATE FUNCTION mastodon_chats_api.messages_visible(in_account_id bigint, in_message_ids bigint[]) RETURNS bigint[]
    LANGUAGE sql STABLE
    AS $$
select			coalesce (
				"array_agg" ("message_id"),
				'{}'
			)
	from		"chats"."messages"
	where		"message_id" = any ("in_message_ids")
		and	"chats"."message_visible_to_account" (
				"message_id",
				"in_account_id"
			)
$$;


--
-- Name: search_chat_messages(bigint, text, smallint, integer); Type: FUNCTION; Schema: mastodon_chats_api; Owner: -
--

CREATE FUNCTION mastodon_chats_api.search_chat_messages(in_account_id bigint, in_search_query text, in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
select			"jsonb_agg" (
				"to_jsonb" ("x")
			)
	from		"mastodon_chats_logic"."search_chat_messages" (
				"in_account_id",
				"in_search_query",
				"in_limit",
				"in_offset"
			) "x"
$$;


--
-- Name: search_chats_and_followers(bigint, text, smallint, integer); Type: FUNCTION; Schema: mastodon_chats_api; Owner: -
--

CREATE FUNCTION mastodon_chats_api.search_chats_and_followers(in_account_id bigint, in_search_query text, in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
select			"jsonb_agg" ("a")
	from		"mastodon_chats_logic"."search_chats_and_followers" (
				"in_account_id",
				"in_search_query",
				"in_limit",
				"in_offset"
			) "a"
$$;


--
-- Name: FUNCTION search_chats_and_followers(in_account_id bigint, in_search_query text, in_limit smallint, in_offset integer); Type: COMMENT; Schema: mastodon_chats_api; Owner: -
--

COMMENT ON FUNCTION mastodon_chats_api.search_chats_and_followers(in_account_id bigint, in_search_query text, in_limit smallint, in_offset integer) IS 'Return avatars for existing chats and followers matching search input.';


--
-- Name: search_preview(bigint, smallint); Type: FUNCTION; Schema: mastodon_chats_api; Owner: -
--

CREATE FUNCTION mastodon_chats_api.search_preview(in_account_id bigint, in_limit smallint DEFAULT 4) RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
select			"jsonb_agg" ("a")
	from		"mastodon_chats_logic"."search_preview" (
				"in_account_id",
				"in_limit"
			) "a"
$$;


--
-- Name: FUNCTION search_preview(in_account_id bigint, in_limit smallint); Type: COMMENT; Schema: mastodon_chats_api; Owner: -
--

COMMENT ON FUNCTION mastodon_chats_api.search_preview(in_account_id bigint, in_limit smallint) IS 'Return default preview avatars for search before input is received.';


--
-- Name: chat_avatar_change_payload(bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.chat_avatar_change_payload(in_event_id bigint) RETURNS mastodon_chats_logic.chat_avatar_change_payload
    LANGUAGE sql STABLE
    AS $$
select			"mastodon_logic"."account_avatar" (
				case "c"."chat_type"
					when	'direct'
					then	"chats"."other_direct_chat_member" (
							"c"."chat_id",
							"c"."owner_account_id"
						)
					when	'channel'
					then	"c"."owner_account_id"
				end
			)
	from		"chats"."chats" "c"
	where		exists (
				select			1
					from		"chat_events"."events" "e"
					where		"e"."event_id" = "in_event_id"
						and	"e"."chat_id" = "c"."chat_id"
			)
$$;


--
-- Name: chat_creation_payload(bigint, bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.chat_creation_payload(in_event_id bigint, in_account_id bigint) RETURNS mastodon_chats_logic.chat_creation_payload
    LANGUAGE sql STABLE
    AS $$
select			"c"."owner_account_id",
			extract ('epoch' from "c"."message_expiration")::int4,
			case "c"."chat_type"
				when	'direct'
				then	"to_jsonb" (
						row (
							"c"."chat_type"
						)::"mastodon_chats_logic"."chat_creation_payload_chat_direct"
					)
				when	'channel'
				then	"to_jsonb" (
						row (
							"c"."chat_type",
							"chats"."subscriber_count" ("c"."chat_id")
						)::"mastodon_chats_logic"."chat_creation_payload_chat_channel"
					)
			end,
			"mastodon_logic"."account_avatar" (
				case "c"."chat_type"
					when	'direct'
					then	"chats"."other_direct_chat_member" (
							"c"."chat_id",
							"in_account_id"
						)
					when	'channel'
					then	"c"."owner_account_id"
				end
			),
			"b"."silenced"
	from		"chats"."chats" "c"
	join		"chats"."members" "b"
		using	("chat_id")
	where		"b"."account_id" = "in_account_id"
		and	exists (
				select			1
					from		"chat_events"."events" "e"
					where		"e"."event_id" = "in_event_id"
						and	"e"."chat_id" = "c"."chat_id"
			)
$$;


--
-- Name: chat_message_expiration_change(bigint, integer, interval); Type: PROCEDURE; Schema: mastodon_chats_logic; Owner: -
--

CREATE PROCEDURE mastodon_chats_logic.chat_message_expiration_change(IN in_account_id bigint, IN in_chat_id integer, IN in_message_expiration interval)
    LANGUAGE plpgsql
    AS $$
declare
	"var_chat_type"			"chats"."chat_type";
	"var_old_message_expiration"	interval;
	"var_owner_account_id"		int8;
begin
	select			"message_expiration",
				"chat_type",
				"owner_account_id"
		into		"var_old_message_expiration",
				"var_chat_type",
				"var_owner_account_id"
		from		"chats"."chats"
		where		"chat_id" = "in_chat_id";
	if (
		"var_chat_type" <> 'direct'
	and	"var_owner_account_id" <> "in_account_id"
	) then
		raise exception 'Cannot change message expiration time for chat type % unless you are the owner!',
			"var_chat_type";
	end if;
	if "var_old_message_expiration" <> "in_message_expiration" then
		insert into		"chats"."chat_message_expiration_changes" (
						"chat_id",
						"message_expiration",
						"changed_by_account_id"
					)
			values		(
						"in_chat_id",
						"in_message_expiration",
						"in_account_id"
					);
		update			"chats"."chats"
			set		"message_expiration" = "in_message_expiration"
			where		"chat_id" = "in_chat_id";
	end if;
end
$$;


--
-- Name: chat_message_expiration_change_payload(bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.chat_message_expiration_change_payload(in_event_id bigint) RETURNS mastodon_chats_logic.chat_message_expiration_change_payload
    LANGUAGE sql STABLE
    AS $$
select			extract ('epoch' from "message_expiration")::int4,
			"changed_by_account_id"
	from		"chat_events"."chat_message_expiration_changes"
	where		"event_id" = "in_event_id"
$$;


--
-- Name: event_create(integer, timestamp with time zone, chat_events.event_type, jsonb); Type: PROCEDURE; Schema: mastodon_chats_logic; Owner: -
--

CREATE PROCEDURE mastodon_chats_logic.event_create(IN in_chat_id integer, IN in_timestamp timestamp with time zone, IN in_event_type chat_events.event_type, IN in_payload jsonb DEFAULT NULL::jsonb)
    LANGUAGE plpgsql
    AS $$
declare
	"var_event_id"		int8;
begin
	insert into		"chat_events"."events" (
					"chat_id",
					"event_type",
					"timestamp"
				)
		values		(
					"in_chat_id",
					"in_event_type",
					"in_timestamp"
				)
		returning	"event_id"
			into	"var_event_id";
	case "in_event_type"
		when 'chat_message_expiration_changed' then
			insert into		"chat_events"."chat_message_expiration_changes" (
							"event_id",
							"message_expiration",
							"changed_by_account_id"
						)
				values		(
							"var_event_id",
							(("in_payload"->>'message_expiration') || ' seconds')::interval,
							("in_payload"->>'changed_by_account_id')::int8
						);
		when 'chat_silenced' then
			insert into		"chat_events"."chat_silences" (
							"event_id",
							"account_id"
						)
				values		(
							"var_event_id",
							("in_payload"->>'account_id')::int8
						);
		when 'chat_unsilenced' then
			insert into		"chat_events"."chat_unsilences" (
							"event_id",
							"account_id"
						)
				values		(
							"var_event_id",
							("in_payload"->>'account_id')::int8
						);
		when 'member_invited' then
			insert into		"chat_events"."member_invitations" (
							"event_id",
							"invited_account_id",
							"invited_by_account_id"
						)
				values		(
							"var_event_id",
							("in_payload"->>'invited_account_id')::int8,
							("in_payload"->>'invited_by_account_id')::int8
						);
		when 'member_joined' then
			insert into		"chat_events"."member_joins" (
							"event_id",
							"account_id"
						)
				values		(
							"var_event_id",
							("in_payload"->>'account_id')::int8
						);
		when 'member_left' then
			insert into		"chat_events"."member_leaves" (
							"event_id",
							"account_id"
						)
				values		(
							"var_event_id",
							("in_payload"->>'account_id')::int8
						);
		when 'member_rejoined' then
			insert into		"chat_events"."member_rejoins" (
							"event_id",
							"account_id"
						)
				values		(
							"var_event_id",
							("in_payload"->>'account_id')::int8
						);
		when 'subscriber_left' then
			insert into		"chat_events"."subscriber_leaves" (
							"event_id",
							"account_id"
						)
				values		(
							"var_event_id",
							("in_payload"->>'account_id')::int8
						);
		when 'subscriber_rejoined' then
			insert into		"chat_events"."subscriber_rejoins" (
							"event_id",
							"account_id"
						)
				values		(
							"var_event_id",
							("in_payload"->>'account_id')::int8
						);
		when 'member_latest_read_message_changed' then
			insert into		"chat_events"."member_latest_read_message_changes" (
							"event_id",
							"account_id"
						)
				values		(
							"var_event_id",
							("in_payload"->>'account_id')::int8
						);
		when 'message_created' then
			insert into		"chat_events"."message_creations" (
							"event_id",
							"message_id"
						)
				values		(
							"var_event_id",
							("in_payload"->>'message_id')::int8
						);
		when 'message_edited' then
			insert into		"chat_events"."message_edits" (
							"event_id",
							"message_id"
						)
				values		(
							"var_event_id",
							("in_payload"->>'message_id')::int8
						);
		when 'message_hidden' then
			insert into		"chat_events"."message_hides" (
							"event_id",
							"message_id",
							"account_id"
						)
				values		(
							"var_event_id",
							("in_payload"->>'message_id')::int8,
							("in_payload"->>'account_id')::int8
						);
		when 'message_deleted' then
			insert into		"chat_events"."message_deletions" (
							"event_id",
							"message_id"
						)
				values		(
							"var_event_id",
							("in_payload"->>'message_id')::int8
						);
		when 'message_reactions_changed' then
			insert into		"chat_events"."message_reactions_changes" (
							"event_id",
							"message_id"
						)
				values		(
							"var_event_id",
							("in_payload"->>'message_id')::int8
						);
		when 'member_avatar_changed' then
			insert into		"chat_events"."member_avatar_changes" (
							"event_id",
							"account_id"
						)
				values		(
							"var_event_id",
							("in_payload"->>'account_id')::int8
						);
		else
			null;
	end case;
end
$$;


--
-- Name: events(smallint, bigint, integer, smallint, bigint, bigint, boolean, smallint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.events(in_api_version smallint, in_account_id bigint, in_chat_id integer DEFAULT NULL::integer, in_upgrade_from_api_version smallint DEFAULT NULL::smallint, in_greater_than_event_id bigint DEFAULT NULL::bigint, in_less_than_event_id bigint DEFAULT NULL::bigint, in_order_ascending boolean DEFAULT true, in_page_size smallint DEFAULT 20) RETURNS SETOF mastodon_chats_logic.event
    LANGUAGE sql STABLE
    AS $$
select			"e"."event_id",
			"e"."chat_id",
			case
				when	(
						"e"."event_type" = 'message_created'
					and	"in_api_version" < 2
					and	exists (
							select			1
								from		"chat_events"."message_creations" "c"
								join		"chats"."messages" "m"
									using	("message_id")
									where		"c"."event_id" = "e"."event_id"
									and	"m"."message_type" = 'media'
						)
					)
				then	'feature_unavailable'
				else	"e"."event_type"
			end,
			"mastodon_logic"."format_timestamp" ("e"."timestamp"),
			case "e"."event_type"
				when	'chat_created'
				then	"to_jsonb" ("mastodon_chats_logic"."chat_creation_payload" ("e"."event_id", "in_account_id"))
				when	'chat_message_expiration_changed'
				then	"to_jsonb" ("mastodon_chats_logic"."chat_message_expiration_change_payload" ("e"."event_id"))
				when	'member_invited'
				then	"to_jsonb" ("mastodon_chats_logic"."member_invitation_payload" ("e"."event_id"))
				when	'member_joined'
				then	"to_jsonb" ("mastodon_chats_logic"."member_join_payload" ("e"."event_id"))
				when	'member_left'
				then	"to_jsonb" ("mastodon_chats_logic"."member_leave_payload" ("e"."event_id"))
				when	'member_rejoined'
				then	"to_jsonb" ("mastodon_chats_logic"."member_rejoin_payload" ("e"."event_id", "in_account_id"))
				when	'subscriber_left'
				then	"to_jsonb" ("mastodon_chats_logic"."subscriber_leave_payload" ("e"."event_id"))
				when	'subscriber_rejoined'
				then	"to_jsonb" ("mastodon_chats_logic"."subscriber_rejoin_payload" ("e"."event_id"))
				when	'member_latest_read_message_changed'
				then	"to_jsonb" ("mastodon_chats_logic"."member_latest_read_message_change_payload" ("e"."event_id"))
				when	'message_created'
				then	case
						when	(
								"in_api_version" < 2
							and	exists (
									select			1
										from		"chat_events"."message_creations" "c"
										join		"chats"."messages" "m"
											using	("message_id")
										where		"c"."event_id" = "e"."event_id"
											and	"m"."message_type" = 'media'
								)
							)
						then	"jsonb_build_object" (
								'text',		'Update your app to see additional content in the chat.',
								'url',		'https://apps.apple.com/us/app/truth-social/id1586018825',
								'button_text',	'Update'
							)
						else	"to_jsonb" ("mastodon_chats_logic"."message_creation_payload" ("e"."event_id", "in_account_id"))
					end
				when	'message_edited'
				then	"to_jsonb" ("mastodon_chats_logic"."message_edit_payload" ("e"."event_id", "in_account_id"))
				when	'message_hidden'
				then	"to_jsonb" ("mastodon_chats_logic"."message_hidden_payload" ("e"."event_id"))
				when	'message_deleted'
				then	"to_jsonb" ("mastodon_chats_logic"."message_deletion_payload" ("e"."event_id"))
				when	'message_reactions_changed'
				then	"to_jsonb" ("mastodon_chats_logic"."message_reactions_change_payload" ("e"."event_id", "in_account_id"))
				when	'chat_avatar_changed'
				then	"to_jsonb" ("mastodon_chats_logic"."chat_avatar_change_payload" ("e"."event_id"))
				when	'member_avatar_changed'
				then	"to_jsonb" ("mastodon_chats_logic"."member_avatar_change_payload" ("e"."event_id"))
			end
	from		"mastodon_chats_logic"."events_basic" (
				"in_api_version",
				"in_account_id",
				"in_chat_id",
				"in_upgrade_from_api_version",
				"in_greater_than_event_id",
				"in_less_than_event_id",
				"in_order_ascending",
				"in_page_size"
			) "e"
$$;


--
-- Name: events_basic(smallint, bigint, integer, smallint, bigint, bigint, boolean, smallint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.events_basic(in_api_version smallint, in_account_id bigint, in_chat_id integer DEFAULT NULL::integer, in_upgrade_from_api_version smallint DEFAULT NULL::smallint, in_greater_than_event_id bigint DEFAULT NULL::bigint, in_less_than_event_id bigint DEFAULT NULL::bigint, in_order_ascending boolean DEFAULT true, in_page_size smallint DEFAULT 20) RETURNS SETOF mastodon_chats_logic.event_basic
    LANGUAGE sql STABLE
    SET plan_cache_mode TO 'force_custom_plan'
    AS $$
with "events" (
	"event_id",
	"chat_id",
	"event_type",
	"timestamp"
) as (
	select			"e"."event_id",
				"e"."chat_id",
				"e"."event_type",
				"e"."timestamp"
		from		"chat_events"."events" "e"
		where		case
					when	"in_chat_id" is not null
					then	"e"."chat_id" = "in_chat_id"
					else	true
				end
			and	case
					when	"in_greater_than_event_id" is not null
					then	"e"."event_id" > "in_greater_than_event_id"
					else	true
				end
			and	case
					when	"in_less_than_event_id" is not null
					then	"e"."event_id" < "in_less_than_event_id"
					else	true
				end
			and	exists (
					select			1
						from		"chats"."members" "b"
						where		"b"."account_id" = "in_account_id"
							and	"b"."chat_id" = "e"."chat_id"
							and	"b"."active"
							and	(
									"e"."event_type" = 'chat_created'
								or	"b"."oldest_visible_at" <= "e"."timestamp"
								)
				) -- Active members/subscribers should see all events newer than their oldest_visible_at, as well as chat_created events
			and	not (
					"e"."event_type" = 'message_hidden'
				and	not exists (
						select			1
							from		"chat_events"."message_hides" "v"
							where		"v"."event_id" = "e"."event_id"
								and	"v"."account_id" = "in_account_id"
					)
				) -- Message hides only visible to account that hid the messages
			and	not (
					"e"."event_type" = 'chat_silenced'
				and	not exists (
						select			1
							from		"chat_events"."chat_silences" "s"
							where		"s"."event_id" = "e"."event_id"
								and	"s"."account_id" = "in_account_id"
					)
				) -- Chat silences only visible to account that silenced the chat
			and	not (
					"e"."event_type" = 'chat_unsilenced'
				and	not exists (
						select			1
							from		"chat_events"."chat_unsilences" "u"
							where		"u"."event_id" = "e"."event_id"
								and	"u"."account_id" = "in_account_id"
					)
				) -- Chat unsilences only visible to account that unsilenced the chat
			and	not (
					"e"."event_type" = 'subscriber_left'
				and	not exists (
						select			1
							from		"chat_events"."subscriber_leaves" "l"
							where		"l"."event_id" = "e"."event_id"
								and	"l"."account_id" = "in_account_id"
					)
				) -- Subscriber leaves only visible to account that left
			and	not (
					"e"."event_type" = 'subscriber_rejoined'
				and	not exists (
						select			1
							from		"chat_events"."subscriber_rejoins" "r"
							where		"r"."event_id" = "e"."event_id"
								and	"r"."account_id" = "in_account_id"
					)
				) -- Subscriber rejoins only visible to account that rejoined
			and	case
					when	"in_api_version" <= "in_upgrade_from_api_version"
					then	false
					when	(
							"in_api_version" > "in_upgrade_from_api_version"
						and	"in_upgrade_from_api_version" = 1
						)
					then	(
							"e"."event_type" = 'message_created'
						and	exists (
								select			1
									from		"chat_events"."message_creations" "c"
									join		"chats"."messages" "m"
										using	("message_id")
									where		"c"."event_id" = "e"."event_id"
										and	"m"."message_type" = 'media'
							)
						) -- Upgrade from API v1 - media messages
					else	true
				end
			and	not (
					"e"."event_type" = 'message_edited'
				and	"in_api_version" < 2
				) -- Message editing (for media messages when videos are uploaded to Rumble) only returned when API version >= 2
				-- We don't return these for API upgrades because they are only relevant for media messages which were not supported in API v1
	union all
	select			"e"."event_id",
				"e"."chat_id",
				"e"."event_type",
				"e"."timestamp"
		from		"chat_events"."events" "e"
		where		"in_upgrade_from_api_version" is null
			and	"e"."event_id" in (
					select			max ("x"."event_id")
						from		"chat_events"."events" "x"
						join		"chat_events"."member_leaves" "l"
							using	("event_id")
						where		"x"."event_type" = 'member_left'
							and	"l"."account_id" = "in_account_id"
							and	case
									when	"in_chat_id" is not null
									then	"x"."chat_id" = "in_chat_id"
									else	true
								end
							and	case
									when	"in_greater_than_event_id" is not null
									then	"x"."event_id" > "in_greater_than_event_id"
									else	true
								end
							and	case
									when	"in_less_than_event_id" is not null
									then	"x"."event_id" < "in_less_than_event_id"
									else	true
								end
							and	exists (
									select			1
										from		"chats"."members" "b"
										join		"chats"."chats" "c"
											using	("chat_id")
										where		"b"."account_id" = "in_account_id"
											and	"b"."chat_id" = "x"."chat_id"
											and	"b"."active"
								)
						group by	"x"."chat_id"
				) -- Active members should see their most recent leave event
	union all
	select			"e"."event_id",
				"e"."chat_id",
				"e"."event_type",
				"e"."timestamp"
		from		"chat_events"."events" "e"
		where		"in_upgrade_from_api_version" is null
			and	case
					when	"in_chat_id" is not null
					then	"e"."chat_id" = "in_chat_id"
					else	true
				end
			and	case
					when	"in_greater_than_event_id" is not null
					then	"e"."event_id" > "in_greater_than_event_id"
					else	true
				end
			and	case
					when	"in_less_than_event_id" is not null
					then	"e"."event_id" < "in_less_than_event_id"
					else	true
				end
			and	exists (
					select			1
						from		"chats"."members" "b"
						where		"b"."account_id" = "in_account_id"
							and	"b"."chat_id" = "e"."chat_id"
							and	not "b"."active"
							and	"b"."oldest_visible_at" <= "e"."timestamp"
							and	(
									(
										"e"."event_type" = 'member_left'
									and	exists (
											select			1
												from		"chat_events"."member_leaves" "l"
												where		"l"."event_id" = "e"."event_id"
													and	"l"."account_id" = "in_account_id"
										)
									)
								or	(
										"e"."event_type" = 'subscriber_left'
									and	exists (
											select			1
												from		"chat_events"."subscriber_leaves" "l"
												where		"l"."event_id" = "e"."event_id"
													and	"l"."account_id" = "in_account_id"
										)
									)
								)
				) -- Inactive members/subcribers should see an event when they leave
			and	not (
					"e"."event_type" = 'subscriber_left'
				and	not exists (
						select			1
							from		"chat_events"."subscriber_leaves" "l"
							where		"l"."event_id" = "e"."event_id"
								and	"l"."account_id" = "in_account_id"
					)
				) -- Subscriber leaves only visible to account that left
	union all
	select			"e"."event_id",
				"e"."chat_id",
				"e"."event_type",
				"e"."timestamp"
		from		"chat_events"."events" "e"
		where		"in_upgrade_from_api_version" is null
			and	case
					when	"in_chat_id" is not null
					then	"e"."chat_id" = "in_chat_id"
					else	true
				end
			and	case
					when	"in_greater_than_event_id" is not null
					then	"e"."event_id" > "in_greater_than_event_id"
					else	true
				end
			and	case
					when	"in_less_than_event_id" is not null
					then	"e"."event_id" < "in_less_than_event_id"
					else	true
				end
			and	exists (
					select			1
						from		"chats"."deleted_members" "b"
						where		"b"."account_id" = "in_account_id"
							and	"b"."chat_id" = "e"."chat_id"
							and	"e"."event_type" = 'chat_deleted'
				) -- Former members/subscribers of deleted chats should see an event when the chat was deleted
)
select			"event_id",
			"chat_id",
			"event_type",
			"timestamp"
	from		"events"
	order by	case
				when	"in_order_ascending"
				then	"event_id"
				else	"event_id" * -1
			end
	limit		"in_page_size"
$$;


--
-- Name: member_avatar_change_payload(bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.member_avatar_change_payload(in_event_id bigint) RETURNS mastodon_chats_logic.member_avatar_change_payload
    LANGUAGE sql STABLE
    AS $$
select			"account_id",
			"mastodon_logic"."account_avatar" (
				"account_id"
			)
	from		"chat_events"."member_avatar_changes"
	where		"event_id" = "in_event_id"
$$;


--
-- Name: member_invitation_payload(bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.member_invitation_payload(in_event_id bigint) RETURNS mastodon_chats_logic.member_invitation_payload
    LANGUAGE sql STABLE
    AS $$
select			"invited_account_id",
			"invited_by_account_id"
	from		"chat_events"."member_invitations"
	where		"event_id" = "in_event_id"
$$;


--
-- Name: member_join_payload(bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.member_join_payload(in_event_id bigint) RETURNS mastodon_chats_logic.member_join_payload
    LANGUAGE sql STABLE
    AS $$
select			"account_id",
			"mastodon_logic"."account_avatar" (
				"account_id"
			)
	from		"chat_events"."member_joins"
	where		"event_id" = "in_event_id"
$$;


--
-- Name: member_latest_read_message_change_payload(bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.member_latest_read_message_change_payload(in_event_id bigint) RETURNS mastodon_chats_logic.member_latest_read_message_change_payload
    LANGUAGE sql STABLE
    AS $$
select			"b"."account_id",
			"mastodon_logic"."format_timestamp" ("b"."latest_read_message_created_at")
	from		"chats"."members" "b"
	where		exists (
				select			1
					from		"chat_events"."member_latest_read_message_changes" "c"
					join		"chat_events"."events" "e"
						using	("event_id")
					where		"c"."event_id" = "in_event_id"
						and	"c"."account_id" = "b"."account_id"
						and	"e"."chat_id" = "b"."chat_id"
			)
$$;


--
-- Name: member_leave_payload(bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.member_leave_payload(in_event_id bigint) RETURNS mastodon_chats_logic.member_leave_payload
    LANGUAGE sql STABLE
    AS $$
select			"account_id"
	from		"chat_events"."member_leaves"
	where		"event_id" = "in_event_id"
$$;


--
-- Name: member_rejoin_payload(bigint, bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.member_rejoin_payload(in_event_id bigint, in_account_id bigint) RETURNS mastodon_chats_logic.member_rejoin_payload
    LANGUAGE sql STABLE
    AS $$
select			"account_id",
			"mastodon_logic"."account_avatar" (
				"account_id"
			),
			case
				when	"account_id" = "in_account_id"
				then	"mastodon_chats_logic"."chat_creation_payload" (
						(
							select			"e"."event_id"
								from		"chat_events"."events" "e"
								join		"chat_events"."events" "m"
									using	("chat_id")
								where		"e"."event_type" = 'chat_created'
									and	"m"."event_id" = "in_event_id"
						),
						"account_id"
					)
			end
	from		"chat_events"."member_rejoins"
	where		"event_id" = "in_event_id"
$$;


--
-- Name: message(bigint, integer, bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.message(in_account_id bigint, in_chat_id integer, in_message_id bigint) RETURNS mastodon_chats_logic.message
    LANGUAGE plpgsql STABLE
    AS $$
declare
	"var_result"		"mastodon_chats_logic"."message";
begin
	select			"m"."message_id"::text,
				"m"."chat_id"::text,
				"m"."created_by_account_id"::text,
				"m"."message_type",
				"mastodon_logic"."html_content" ("t"."content"),
				"mastodon_logic"."format_timestamp" ("m"."created_at"),
				"m"."created_at" > "chats"."member_latest_read_message_created_at" (
					"in_account_id",
					"in_chat_id"
				),
				extract ('epoch' from "m"."expiration")::int4,
				"mastodon_chats_logic"."message_reactions_array" (
					"in_account_id",
					"m"."message_id"
				),
				"mastodon_chats_logic"."message_media_attachments_array" ("m"."message_id"),
				"upper" ("i"."idempotency_key"::text)
		into		"var_result"
		from		"chats"."messages" "m"
		left join	"chats"."message_text" "t"
			using	("message_id")
		left join	"chats"."message_idempotency_keys" "i"
			using	("message_id")
		where		(
					(
						"m"."message_type" = 'text'
					and	"t"."content" is not null
					)
				or	"m"."message_type" <> 'text'
				)
			and	"m"."chat_id" = "in_chat_id"
			and	"chats"."message_visible_to_account" (
					"m"."message_id",
					"in_account_id"
				)
			and	"m"."message_id" = "in_message_id";
	if not found then
		raise exception 'Message ID % in Chat ID % not found for Account ID %',
			"in_message_id",
			"in_chat_id",
			"in_account_id";
	end if;
	return "var_result";
end
$$;


--
-- Name: message_create(bigint, text, uuid, integer, text, bigint[]); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.message_create(in_account_id bigint, in_oauth_access_token text, in_idempotency_key uuid, in_chat_id integer, in_content text, in_media_attachment_ids bigint[]) RETURNS mastodon_chats_logic.message
    LANGUAGE plpgsql
    AS $$
declare
	"var_created_at"		timestamptz;
	"var_expiration"		interval;
	"var_message_id"		int8;
	"var_message_type"		"chats"."message_type";
	"var_oauth_access_token_id"	int8;
	"var_result"			"mastodon_chats_logic"."message";
begin
	if coalesce ("cardinality" ("in_media_attachment_ids"), 0) > 4 then
		raise exception 'Cannot attach more than 4 media attachments to a message!';
	elsif coalesce ("cardinality" ("in_media_attachment_ids"), 0) > 0 then
		"var_message_type" := 'media';
	elsif coalesce ("length" ("in_content"), 0) > 0 then
		"var_message_type" := 'text';
	else
		raise exception 'Messages must have either text content or media attachments!';
	end if;
	if "in_idempotency_key" is not null then
		select			"t"."id"
			into		"var_oauth_access_token_id"
			from		"public"."oauth_access_tokens" "t"
			join		"public"."users" "u"
				on	"u"."id" = "t"."resource_owner_id"
			where		"token" = "in_oauth_access_token"
				and	"u"."account_id" = "in_account_id";
	end if;
	if "var_oauth_access_token_id" is not null then
		select			"m"."message_id"::text,
					"m"."chat_id"::text,
					"m"."created_by_account_id"::text,
					"m"."message_type",
					"mastodon_logic"."html_content" ("t"."content"),
					"mastodon_logic"."format_timestamp" ("m"."created_at"),
					"m"."created_at" > "chats"."member_latest_read_message_created_at" (
						"in_account_id",
						"in_chat_id"
					),
					extract ('epoch' from "m"."expiration")::int4,
					"mastodon_chats_logic"."message_reactions_array" (
						"in_account_id",
						"m"."message_id"
					),
					"mastodon_chats_logic"."message_media_attachments_array" ("m"."message_id"),
					"upper" ("in_idempotency_key"::text)
			into		"var_result"
			from		"chats"."messages" "m"
			left join	"chats"."message_text" "t"
				using	("message_id")
			where		(
						(
							"m"."message_type" = 'text'
						and	"t"."content" is not null
						)
					or	"m"."message_type" <> 'text'
					)
				and	"m"."chat_id" = "in_chat_id"
				and	"m"."created_by_account_id" = "in_account_id"
				and	exists (
						select			1
							from		"chats"."message_idempotency_keys"
							where		"oauth_access_token_id" = "var_oauth_access_token_id"
								and	"idempotency_key" = "in_idempotency_key"
								and	"message_id" = "m"."message_id"
					);
	end if;
	if "var_result" is null then
		if not "chats"."member_active" ("in_account_id", "in_chat_id") then
			raise exception 'Messages can only be created by members who are currently in the chat!';
		end if;
		insert into		"chats"."messages" (
						"chat_id",
						"message_type",
						"expiration",
						"created_by_account_id"
					)
			values		(
						"in_chat_id",
						"var_message_type",
						"chats"."message_expiration" ("in_chat_id"),
						"in_account_id"
					)
			returning	"message_id",
					"created_at",
					"expiration"
				into	"var_message_id",
					"var_created_at",
					"var_expiration";
		if coalesce ("length" ("in_content"), 0) > 0 then
			insert into		"chats"."message_text" (
							"message_id",
							"content"
						)
				values		(
							"var_message_id",
							"in_content"
						);
		end if;
		if "var_message_type" = 'media' then
			insert into		"chats"."message_media_attachments" (
							"message_id",
							"media_attachment_id"
						)
			select			"var_message_id",
						"unnest" ("in_media_attachment_ids");
		end if;
		if "var_oauth_access_token_id" is not null then
			insert into		"chats"."message_idempotency_keys" (
							"oauth_access_token_id",
							"idempotency_key",
							"message_id"
						)
				values		(
							"var_oauth_access_token_id",
							"in_idempotency_key",
							"var_message_id"
						);
		end if;
		"var_result" := (
			"var_message_id"::text,
			"in_chat_id"::text,
			"in_account_id"::text,
			"var_message_type",
			"mastodon_logic"."html_content" ("in_content"),
			"mastodon_logic"."format_timestamp" ("var_created_at"),
			false,
			extract ('epoch' from "var_expiration")::int4,
			null::"mastodon_chats_logic"."emoji_reaction"[],
			"mastodon_chats_logic"."message_media_attachments_array" ("var_message_id"),
			"upper" ("in_idempotency_key"::text)
		);
	end if;
	return "var_result";
end
$$;


--
-- Name: message_creation_payload(bigint, bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.message_creation_payload(in_event_id bigint, in_account_id bigint) RETURNS mastodon_chats_logic.message_creation_payload
    LANGUAGE sql STABLE
    AS $$
select			"m"."message_id",
			"m"."created_by_account_id",
			"upper" ("k"."idempotency_key"::text),
			extract ('epoch' from "m"."expiration")::int4,
			"mastodon_chats_logic"."message_reactions_array" (
				"in_account_id",
				"t"."message_id"
			),
			"h"."message_id" is not null,
			"m"."created_at" > "b"."latest_read_message_created_at",
			case "m"."message_type"
				when	'text'
				then	"to_jsonb" (
						row (
							"m"."message_type",
							"mastodon_logic"."html_content" ("t"."content")
						)::"mastodon_chats_logic"."message_creation_payload_message_text"
					)
				when	'media'
				then	"to_jsonb" (
						row (
							"m"."message_type",
							"mastodon_logic"."html_content" ("t"."content"),
							"mastodon_chats_logic"."message_media_attachments_array" ("m"."message_id")
						)::"mastodon_chats_logic"."message_creation_payload_message_media"
					)
			end
	from		"chat_events"."message_creations" "e"
	join		"chats"."messages" "m"
		using	("message_id")
	join		"chats"."members" "b"
		on	"b"."chat_id" = "m"."chat_id"
		and	"b"."account_id" = "in_account_id"
	left join	"chats"."message_text" "t"
		using	("message_id")
	left join	"chats"."message_idempotency_keys" "k"
		using	("message_id")
	left join	"chats"."hidden_messages" "h"
		on	"h"."message_id" = "m"."message_id"
		and	"h"."account_id" = "in_account_id"
	where		"e"."event_id" = "in_event_id"
$$;


--
-- Name: message_delete(bigint, bigint); Type: PROCEDURE; Schema: mastodon_chats_logic; Owner: -
--

CREATE PROCEDURE mastodon_chats_logic.message_delete(IN in_account_id bigint, IN in_message_id bigint)
    LANGUAGE plpgsql
    AS $$
declare
	"var_admin"		bool;
begin
	select			"admin"
		into		"var_admin"
		from		"public"."users"
		where		"account_id" = "in_account_id";
	delete from		"chats"."messages"
		where		"message_id" = "in_message_id"
			and	(
					"created_by_account_id" = "in_account_id"
				or	"var_admin"
				);
	if not found then
		raise exception 'Message ID % does not exist or is not owned by Account ID %',
			"in_message_id",
			"in_account_id";
	end if;
end
$$;


--
-- Name: message_deletion_payload(bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.message_deletion_payload(in_event_id bigint) RETURNS mastodon_chats_logic.message_deletion_payload
    LANGUAGE sql STABLE
    AS $$
select			"message_id"
	from		"chat_events"."message_deletions"
	where		"event_id" = "in_event_id"
$$;


--
-- Name: message_edit_payload(bigint, bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.message_edit_payload(in_event_id bigint, in_account_id bigint) RETURNS mastodon_chats_logic.message_creation_payload
    LANGUAGE sql STABLE
    AS $$
select			"m"."message_id",
			"m"."created_by_account_id",
			"k"."idempotency_key",
			extract ('epoch' from "m"."expiration")::int4,
			"mastodon_chats_logic"."message_reactions_array" (
				"in_account_id",
				"t"."message_id"
			),
			"h"."message_id" is not null,
			"m"."created_at" > "b"."latest_read_message_created_at",
			case "m"."message_type"
				when	'text'
				then	"to_jsonb" (
						row (
							"m"."message_type",
							"mastodon_logic"."html_content" ("t"."content")
						)::"mastodon_chats_logic"."message_creation_payload_message_text"
					)
				when	'media'
				then	"to_jsonb" (
						row (
							"m"."message_type",
							"mastodon_logic"."html_content" ("t"."content"),
							"mastodon_chats_logic"."message_media_attachments_array" ("m"."message_id")
						)::"mastodon_chats_logic"."message_creation_payload_message_media"
					)
			end
	from		"chat_events"."message_edits" "e"
	join		"chats"."messages" "m"
		using	("message_id")
	join		"chats"."members" "b"
		on	"b"."chat_id" = "m"."chat_id"
		and	"b"."account_id" = "in_account_id"
	left join	"chats"."message_text" "t"
		using	("message_id")
	left join	"chats"."message_idempotency_keys" "k"
		using	("message_id")
	left join	"chats"."hidden_messages" "h"
		on	"h"."message_id" = "m"."message_id"
		and	"h"."account_id" = "in_account_id"
	where		"e"."event_id" = "in_event_id"
$$;


--
-- Name: message_hidden_payload(bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.message_hidden_payload(in_event_id bigint) RETURNS mastodon_chats_logic.message_hidden_payload
    LANGUAGE sql STABLE
    AS $$
select			"message_id",
			"account_id"
	from		"chat_events"."message_hides"
	where		"event_id" = "in_event_id"
$$;


--
-- Name: message_hide(bigint, bigint); Type: PROCEDURE; Schema: mastodon_chats_logic; Owner: -
--

CREATE PROCEDURE mastodon_chats_logic.message_hide(IN in_account_id bigint, IN in_message_id bigint)
    LANGUAGE sql
    AS $$
insert into		"chats"."hidden_messages" (
				"account_id",
				"message_id"
			)
	values		(
				"in_account_id",
				"in_message_id"
			)
	on		conflict
		do	nothing;
$$;


--
-- Name: message_media_attachments(bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.message_media_attachments(in_message_id bigint) RETURNS SETOF mastodon_chats_logic.media_attachment
    LANGUAGE sql
    AS $$
select			"a"."id",
			case "a"."type"
				when 0 then 'image'
				when 1 then 'gifv'
				when 2 then 'video'
				when 3 then 'unknown'
				when 4 then 'audio'
			end,
			(
				"configuration"."storage_base_url" ()
			||	'/media_attachments/files/'
			||	"to_char" (
					"a"."id",
					'FM999/999/999/999/999/999'
				)
			||	'/original/'
			||	"a"."file_file_name"
			),
			(
				"configuration"."storage_base_url" ()
			||	'/media_attachments/files/'
			||	"to_char" (
					"a"."id",
					'FM999/999/999/999/999/999'
				)
			||	case
					when	"a"."type" = 0
					then	'/small/'
					else	'/original/'
				end
			||	"a"."file_file_name"
			),
			"external_video_id",
			"remote_url",
			null,
			(
				"configuration"."base_url" ()
			||	'/media/'
			||	"a"."shortcode"
			),
			"a"."file_meta",
			"a"."description",
			"a"."blurhash"
	from		"public"."media_attachments" "a"
	where		exists (
				select			1
					from		"chats"."message_media_attachments" "m"
					where		"m"."media_attachment_id" = "a"."id"
						and	"m"."message_id" = "in_message_id"
			)
	order by	"a"."created_at"
$$;


--
-- Name: message_media_attachments_array(bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.message_media_attachments_array(in_message_id bigint) RETURNS mastodon_chats_logic.media_attachment[]
    LANGUAGE sql
    AS $$
select			"array_agg" ("x")
	from		"mastodon_chats_logic"."message_media_attachments" ("in_message_id") "x"
$$;


--
-- Name: message_reaction_add(bigint, bigint, text); Type: PROCEDURE; Schema: mastodon_chats_logic; Owner: -
--

CREATE PROCEDURE mastodon_chats_logic.message_reaction_add(IN in_account_id bigint, IN in_message_id bigint, IN in_emoji text)
    LANGUAGE plpgsql
    AS $$
declare
	"var_emoji_id"		int2;
begin
	"var_emoji_id" := "reference"."emoji_id" ("in_emoji");
	if "var_emoji_id" is null then
		raise exception '% is not a supported emoji!',
			"quote_literal" ("in_emoji");
	end if;
	insert into		"chats"."reactions" (
					"message_id",
					"emoji_id",
					"account_id"
				)
		values		(
					"in_message_id",
					"var_emoji_id",
					"in_account_id"
				);
end
$$;


--
-- Name: message_reaction_info(bigint, bigint, text); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.message_reaction_info(in_account_id bigint, in_message_id bigint, in_emoji text) RETURNS SETOF mastodon_chats_logic.detailed_emoji_reaction
    LANGUAGE sql STABLE
    AS $$
select		"e"."emoji",
		count (1),
		"in_account_id" = any ("array_agg" ("r"."account_id")),
		"array_agg" (
			"mastodon_logic"."account_avatar" ("r"."account_id")
		)
from		"chats"."reactions" "r"
join		"reference"."emojis" "e"
	using	("emoji_id")
where		"r"."message_id" = "in_message_id"
	and	"e"."emoji" = "in_emoji"
group by	1
$$;


--
-- Name: message_reaction_remove(bigint, bigint, text); Type: PROCEDURE; Schema: mastodon_chats_logic; Owner: -
--

CREATE PROCEDURE mastodon_chats_logic.message_reaction_remove(IN in_account_id bigint, IN in_message_id bigint, IN in_emoji text)
    LANGUAGE plpgsql
    AS $$
begin
	delete from		"chats"."reactions"
		where		"message_id" = "in_message_id"
			and	"emoji_id" = "reference"."emoji_id" ("in_emoji")
			and	"account_id" = "in_account_id";
	if not found then
		raise exception 'Specified emoji reaction for message by account does not exist!';
	end if;
end
$$;


--
-- Name: message_reactions(bigint, bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.message_reactions(in_account_id bigint, in_message_id bigint) RETURNS SETOF mastodon_chats_logic.emoji_reaction
    LANGUAGE sql STABLE
    AS $$
select			"e"."emoji",
			count (1),
			"in_account_id" = any ("array_agg" ("r"."account_id"))
	from		"chats"."reactions" "r"
	join		"reference"."emojis" "e"
		using	("emoji_id")
	where		"r"."message_id" = "in_message_id"
	group by	1
	order by	min ("r"."created_at"),
			"e"."emoji"
$$;


--
-- Name: message_reactions_array(bigint, bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.message_reactions_array(in_account_id bigint, in_message_id bigint) RETURNS mastodon_chats_logic.emoji_reaction[]
    LANGUAGE sql STABLE
    AS $$
select			"array_agg" ("x")
	from		"mastodon_chats_logic"."message_reactions" (
				"in_account_id",
				"in_message_id"
			) "x"
$$;


--
-- Name: message_reactions_change_payload(bigint, bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.message_reactions_change_payload(in_event_id bigint, in_account_id bigint) RETURNS mastodon_chats_logic.message_reactions_change_payload
    LANGUAGE sql STABLE
    AS $$
select			"message_id",
			"mastodon_chats_logic"."message_reactions_array" (
				"in_account_id",
				"message_id"
			)
	from		"chat_events"."message_reactions_changes"
	where		"event_id" = "in_event_id"
$$;


--
-- Name: message_unhide(bigint, bigint); Type: PROCEDURE; Schema: mastodon_chats_logic; Owner: -
--

CREATE PROCEDURE mastodon_chats_logic.message_unhide(IN in_account_id bigint, IN in_message_id bigint)
    LANGUAGE plpgsql
    AS $$
begin
	delete from		"chats"."hidden_messages"
		where		"account_id" = "in_account_id"
			and	"message_id" = "in_message_id";
	if not found then
		raise exception 'Cannot unhide Message ID %, as it is not hidden for Account ID %!',
			"in_message_id",
			"in_account_id";
	end if;
end
$$;


--
-- Name: message_with_context(bigint, smallint, smallint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.message_with_context(in_message_id bigint, in_previous_limit smallint, in_next_limit smallint) RETURNS mastodon_chats_logic.message_with_context
    LANGUAGE sql
    AS $$
with "message" (
	"message_id",
	"message_type",
	"created_by_account_id",
	"chat_id",
	"content",
	"created_at",
	"expiration",
	"media_attachments"
) as (
	select			"m"."message_id",
				"m"."message_type",
				"m"."created_by_account_id",
				"m"."chat_id",
				"mastodon_logic"."html_content" ("t"."content"),
				"mastodon_logic"."format_timestamp" ("m"."created_at"),
				extract ('epoch' from "m"."expiration")::int4,
				"mastodon_chats_logic"."message_media_attachments_array" ("m"."message_id")
		from		"chats"."messages" "m"
		left join	"chats"."message_text" "t"
			using	("message_id")
		where		"m"."message_id" = "in_message_id"
),
"previous_messages" (
	"row"
) as (
	select			row (
					"m"."message_id",
					"m"."message_type",
					"m"."created_by_account_id",
					"m"."chat_id",
					"mastodon_logic"."html_content" ("t"."content"),
					"mastodon_logic"."format_timestamp" ("m"."created_at"),
					extract ('epoch' from "m"."expiration")::int4,
					"mastodon_chats_logic"."message_media_attachments_array" ("m"."message_id")
				)::"mastodon_chats_logic"."message_for_janus"
		from		"chats"."messages" "m"
		join		"chats"."message_text" "t"
			using	("message_id")
		where		"m"."chat_id" = (
					select			"chat_id"
						from		"message"
				)
			and	"m"."message_id" < "in_message_id"
		order by	"m"."message_id" desc
		limit		least ("in_previous_limit", 20)
),
"next_messages" (
	"row"
) as (
	select			row (
					"m"."message_id",
					"m"."message_type",
					"m"."created_by_account_id",
					"m"."chat_id",
					"mastodon_logic"."html_content" ("t"."content"),
					"mastodon_logic"."format_timestamp" ("m"."created_at"),
					extract ('epoch' from "m"."expiration")::int4,
					"mastodon_chats_logic"."message_media_attachments_array" ("m"."message_id")
				)::"mastodon_chats_logic"."message_for_janus"
		from		"chats"."messages" "m"
		join		"chats"."message_text" "t"
			using	("message_id")
		where		"m"."chat_id" = (
					select			"chat_id"
						from		"message"
				)
			and	"m"."message_id" > "in_message_id"
		order by	"m"."message_id"
		limit		least ("in_next_limit", 20)
)
select			(
				select			(
								"message_id",
								"message_type",
								"created_by_account_id",
								"chat_id",
								"content",
								"created_at",
								"expiration",
								"media_attachments"
							)::"mastodon_chats_logic"."message_for_janus"
					from		"message"
			),
			(
				select			"array_agg" ("row")
					from		"previous_messages"
			),
			(
				select			"array_agg" ("row")
					from		"next_messages"
			)
$$;


--
-- Name: messages(bigint, integer, bigint, bigint, boolean, smallint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.messages(in_account_id bigint, in_chat_id integer, in_minimum_message_id bigint DEFAULT NULL::bigint, in_maximum_message_id bigint DEFAULT NULL::bigint, in_order_ascending boolean DEFAULT true, in_page_size smallint DEFAULT 20) RETURNS SETOF mastodon_chats_logic.message
    LANGUAGE sql STABLE
    AS $$
select			"m"."message_id"::text,
			"m"."chat_id"::text,
			"m"."created_by_account_id"::text,
			"m"."message_type",
			"mastodon_logic"."html_content" ("t"."content"),
			"mastodon_logic"."format_timestamp" ("m"."created_at"),
			"m"."created_at" > "chats"."member_latest_read_message_created_at" (
				"in_account_id",
				"in_chat_id"
			),
			extract ('epoch' from "m"."expiration")::int4,
			"mastodon_chats_logic"."message_reactions_array" (
				"in_account_id",
				"m"."message_id"
			),
			"mastodon_chats_logic"."message_media_attachments_array" ("m"."message_id"),
			"upper" ("i"."idempotency_key"::text)
	from		"chats"."messages" "m"
	left join	"chats"."message_text" "t"
		using	("message_id")
	left join	"chats"."message_idempotency_keys" "i"
		using	("message_id")
	where		(
				(
					"m"."message_type" = 'text'
				and	"t"."content" is not null
				)
			or	"m"."message_type" <> 'text'
			)
		and	"m"."chat_id" = "in_chat_id"
		and	"chats"."message_visible_to_account" (
				"m"."message_id",
				"in_account_id"
			)
		and	case
				when	"in_minimum_message_id" is not null
				then	"m"."message_id" > "in_minimum_message_id"
				else	true
			end
		and	case
				when	"in_maximum_message_id" is not null
				then	"m"."message_id" < "in_maximum_message_id"
				else	true
			end
	order by	case
				when	"in_order_ascending"
				then	"message_id"
				else	"message_id" * -1
			end
	limit		"in_page_size"
$$;


--
-- Name: oauth_access_token_id_and_account(text); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.oauth_access_token_id_and_account(in_oauth_access_token text) RETURNS TABLE(oauth_access_token_id bigint, account_id bigint)
    LANGUAGE sql STABLE
    AS $$
select			"t"."id",
			"u"."account_id"
	from		"public"."oauth_access_tokens" "t"
	join		"public"."users" "u"
		on	"u"."id" = "t"."resource_owner_id"
	where		"t"."token" = "in_oauth_access_token"
$$;


--
-- Name: search_chat_messages(bigint, text, smallint, integer); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.search_chat_messages(in_account_id bigint, in_search_query text, in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS SETOF mastodon_chats_logic.chat_message_search_result
    LANGUAGE plpgsql STABLE
    AS $$
declare
	"var_search_query"	text;
begin
	"var_search_query" := (
		nullif (
			"websearch_to_tsquery" (
				'simple',
				"in_search_query"
			)::text,
			''
		)
	||	':*'
	);
	return query (
		with "messages" (
			"message_id",
			"rank"
		) as (
			select			"t"."message_id",
						"ts_rank" (
							"to_tsvector" (
								'simple',
								"t"."content"
							),
							"to_tsquery" (
								'simple',
								"var_search_query"
							)
						)
				from		"chats"."message_text" "t"
				where		exists (
							select			1
								from		"chats"."messages" "m"
								join		"chats"."chats" "c"
									using	("chat_id")
								where		"c"."chat_type" = 'direct'
									and	"m"."message_id" = "t"."message_id"
						)
					and	"chats"."message_visible_to_account" (
							"t"."message_id",
							"in_account_id"
						)
					and	(
							"to_tsvector" (
								'simple',
								"t"."content"
							)
						@@	"to_tsquery" (
								'simple',
								"var_search_query"
							)
						)
				limit		"in_limit"
					offset	"in_offset"
		)
		select			"mastodon_logic"."account_avatar" (
						"chats"."other_direct_chat_member" (
							"m"."chat_id",
							"in_account_id"
						)
					),
					"m"."message_id"::text,
					"m"."chat_id"::text,
					"ts_headline" (
						'simple',
						replace (
							replace (
								replace (
									"t"."content",
									'&',
									'&amp;'
								),
								'<',
								'&lt;'
							),
							'>',
							'&gt;'
						),
						"to_tsquery" (
							'simple',
							"var_search_query"
						),
						'HighlightAll=1'
					)
			from		"messages" "x"
			join		"chats"."messages" "m"
				using	("message_id")
			join		"chats"."message_text" "t"
				using	("message_id")
			order by	"x"."rank" desc,
					"x"."message_id" desc
	);
end
$$;


--
-- Name: search_chats_and_followers(bigint, text, smallint, integer); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.search_chats_and_followers(in_account_id bigint, in_search_query text, in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS SETOF mastodon_logic.account_avatar
    LANGUAGE plpgsql STABLE
    SET plan_cache_mode TO 'force_custom_plan'
    AS $$
declare
	"var_account"			int8;
	"var_chats"			int8[];
	"var_chats_count"		int8;
	"var_search_query"		text;
	"var_follower_limit"		int2;
	"var_follower_offset"		int4;
	"var_followers"			int8[];
begin
	"var_search_query" := '%'||"regexp_replace" ("in_search_query", '([%_])', '\\\1', 'g')||'%';
	with "accounts" ("id") as (
		select			"a"."id"
			from		"public"."accounts" "a"
			where		(
						"a"."username" ilike "var_search_query"
					or	"a"."display_name" ilike "var_search_query"
					)
				and	exists (
						select			1
							from		"chats"."chats" "c"
							join		"chats"."members" "m"
								using	("chat_id")
							join		"chats"."members" "o"
								using	("chat_id")
							where		"c"."chat_type" = 'direct'
								and	"o"."account_id" <> "m"."account_id"
								and	"m"."account_id" = "in_account_id"
								and	"o"."account_id" = "a"."id"
					)
			order by	lower ("a"."username")
	)
	select			("array_agg" ("id"))["in_offset" + 1:"in_limit" + "in_offset"],
				"count" (1)
		into		"var_chats",
				"var_chats_count"
		from		"accounts";
	"var_follower_limit" := "in_limit" - coalesce ("var_chats_count", 0);
	if "var_follower_limit" > 0 then
		"var_follower_offset" := case when "in_offset" > "var_chats_count" then abs ("var_chats_count" - "in_offset") else 0 end;
		with "accounts" ("id") as (
			select			"a"."id"
				from		"public"."accounts" "a"
				where		"a"."accepting_messages"
					and	(
							"a"."username" ilike "var_search_query"
						or	"a"."display_name" ilike "var_search_query"
						)
					and	exists (
							select			1
								from		"public"."follows" "f"
								where		"f"."account_id" = "a"."id"
									and	"f"."target_account_id" = "in_account_id"
									and	not exists (
											select			1
												from		"chats"."chats" "c"
												join		"chats"."members" "m"
													using	("chat_id")
												join		"chats"."members" "o"
													using	("chat_id")
												where		"c"."chat_type" = 'direct'
													and	"o"."account_id" <> "m"."account_id"
													and	"m"."account_id" = "f"."target_account_id"
													and	"o"."account_id" = "f"."account_id"
										)
						)
				order by	lower ("a"."username")
				limit		"var_follower_limit"
					offset	"var_follower_offset"
		)
		select			"array_agg" ("id")
			into		"var_followers"
			from		"accounts";
	end if;
	for "var_account" in select "unnest" ("var_chats"||"var_followers") loop
		return next "mastodon_logic"."account_avatar" ("var_account");
	end loop;
end
$$;


--
-- Name: search_preview(bigint, smallint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.search_preview(in_account_id bigint, in_limit smallint DEFAULT 4) RETURNS SETOF mastodon_logic.account_avatar
    LANGUAGE plpgsql STABLE
    SET plan_cache_mode TO 'force_custom_plan'
    AS $$
declare
	"var_account"			int8;
	"var_chats"			int8[];
	"var_chats_count"		int8;
	"var_follower_limit"		int2;
	"var_followers"			int8[];
begin
	with "accounts" ("id") as (
		select			"o"."account_id"
			from		"chats"."chats" "c"
			join		"chats"."members" "b"
				using	("chat_id")
			join		"chats"."members" "o"
				using	("chat_id")
			left join	lateral (
						select			max ("x"."created_at")
							from		"chats"."messages" "x"
							where		"x"."chat_id" = "c"."chat_id"
					) "m" ("created_at")
				on	true
			where		"c"."chat_type" = 'direct'
				and	"o"."account_id" <> "b"."account_id"
				and	"b"."account_id" = "in_account_id"
			order by	"m"."created_at" desc nulls last,
					"c"."created_at" desc
	)
	select			("array_agg" ("id"))[1:"in_limit"],
				"count" (1)
		into		"var_chats",
				"var_chats_count"
		from		"accounts";
	"var_follower_limit" := "in_limit" - coalesce ("var_chats_count", 0);
	if "var_follower_limit" > 0 then
		with "accounts" ("id") as (
			select			"a"."id"
				from		"public"."accounts" "a"
				where		"a"."accepting_messages"
					and	exists (
							select			1
								from		"public"."follows" "f"
								where		"f"."account_id" = "a"."id"
									and	"f"."target_account_id" = "in_account_id"
									and	not exists (
											select			1
												from		"chats"."chats" "c"
												join		"chats"."members" "m"
													using	("chat_id")
												join		"chats"."members" "o"
													using	("chat_id")
												where		"c"."chat_type" = 'direct'
													and	"o"."account_id" <> "m"."account_id"
													and	"m"."account_id" = "f"."target_account_id"
													and	"o"."account_id" = "f"."account_id"
										)
						)
				order by	"random" ()
				limit		"var_follower_limit"
		)
		select			"array_agg" ("id")
			into		"var_followers"
			from		"accounts";
	end if;
	for "var_account" in select "unnest" ("var_chats"||"var_followers") loop
		return next "mastodon_logic"."account_avatar" ("var_account");
	end loop;
end
$$;


--
-- Name: subscriber_leave_payload(bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.subscriber_leave_payload(in_event_id bigint) RETURNS mastodon_chats_logic.subscriber_leave_payload
    LANGUAGE sql STABLE
    AS $$
select			"account_id"
	from		"chat_events"."subscriber_leaves"
	where		"event_id" = "in_event_id"
$$;


--
-- Name: subscriber_rejoin_payload(bigint); Type: FUNCTION; Schema: mastodon_chats_logic; Owner: -
--

CREATE FUNCTION mastodon_chats_logic.subscriber_rejoin_payload(in_event_id bigint) RETURNS mastodon_chats_logic.subscriber_rejoin_payload
    LANGUAGE sql STABLE
    AS $$
select			"account_id",
			"mastodon_chats_logic"."chat_creation_payload" (
				(
					select			"e"."event_id"
						from		"chat_events"."events" "e"
						join		"chat_events"."events" "m"
							using	("chat_id")
						where		"e"."event_type" = 'chat_created'
							and	"m"."event_id" = "in_event_id"
				),
				"account_id"
			)
	from		"chat_events"."subscriber_rejoins"
	where		"event_id" = "in_event_id"
$$;


--
-- Name: account_avatar(bigint); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.account_avatar(in_account_id bigint) RETURNS mastodon_logic.account_avatar
    LANGUAGE sql STABLE
    AS $$
select			"a"."id"::text,
			"a"."username",
			"a"."username",
			(
				"configuration"."base_url" ()
			||	'/@'
			||	"a"."username"
			),
			"mastodon_logic"."image_url" (
				'accounts',
				'avatars',
				"a"."id",
				"a"."avatar_file_name"
			),
			"mastodon_logic"."image_static_url" (
				'accounts',
				'avatars',
				"a"."id",
				"a"."avatar_file_name",
				"a"."avatar_content_type"::"public"."image_content_type"
			),
			"display_name",
			"verified"
	from		"public"."accounts" "a"
	where		"a"."id" = "in_account_id"
$$;


--
-- Name: format_timestamp(timestamp without time zone); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.format_timestamp(in_timestamp timestamp without time zone) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
select			to_char (
				"in_timestamp",
				'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'
			)
$$;


--
-- Name: format_timestamp(timestamp with time zone); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.format_timestamp(in_timestamp timestamp with time zone) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
select			to_char (
				"in_timestamp" at time zone 'UTC',
				'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'
			)
$$;


--
-- Name: group(bigint); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic."group"(in_group_id bigint) RETURNS mastodon_logic."group"
    LANGUAGE sql STABLE
    AS $$
select			"g"."id",
			"g"."display_name",
			"mastodon_logic"."format_timestamp" ("g"."created_at"),
			row ("g"."owner_account_id")::"mastodon_logic"."group_owner",
			"mastodon_logic"."html_content" ("g"."note"),
			"mastodon_logic"."image_url" (
				'groups',
				'avatars',
				"g"."id",
				"g"."avatar_file_name"
			),
			"mastodon_logic"."image_static_url" (
				'groups',
				'avatars',
				"g"."id",
				"g"."avatar_file_name",
				"g"."avatar_content_type"
			),
			"mastodon_logic"."image_url" (
				'groups',
				'headers',
				"g"."id",
				"g"."header_file_name"
			),
			"mastodon_logic"."image_static_url" (
				'groups',
				'headers',
				"g"."id",
				"g"."header_file_name",
				"g"."header_content_type"
			),
			"g"."statuses_visibility",
			true,
			null,
			"g"."discoverable",
			"g"."locked",
			"s"."members_count",
			coalesce (
				(
				select			"array_agg" ("x")
					from		"mastodon_logic"."group_tags_simple" ("g"."id") "x"
				),
				array[]::"mastodon_logic"."tag_simple"[]
			),
			"g"."slug",
			"mastodon_logic"."group_url" ("g"."slug"),
			"mastodon_logic"."format_timestamp" ("g"."deleted_at"),
			row ("g"."note")::"mastodon_logic"."group_source"
	from		"public"."groups" "g"
	join		"public"."group_stats" "s"
		on	"s"."group_id" = "g"."id"
	where		"g"."id" = "in_group_id"
$$;


--
-- Name: group_latest_activity(bigint, bigint); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.group_latest_activity(in_account_id bigint, in_group_id bigint) RETURNS timestamp without time zone
    LANGUAGE sql STABLE
    AS $$
select			coalesce (
				(
					select			"max" ("created_at")
						from		"public"."statuses"
						where		"group_id" = "in_group_id"
							and	"account_id" = "in_account_id"
							and	"deleted_at" is null
				),
				(
					select			"created_at"
						from		"public"."group_memberships"
						where		"group_id" = "in_group_id"
							and	"account_id" = "in_account_id"
				),
				(
					select			"created_at"
						from		"public"."group_membership_requests"
						where		"group_id" = "in_group_id"
							and	"account_id" = "in_account_id"
				)
			)
$$;


--
-- Name: group_tag_statistics(bigint, bigint); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.group_tag_statistics(in_group_id bigint, in_tag_id bigint) RETURNS mastodon_logic.tag_statistics
    LANGUAGE sql STABLE
    AS $$
with "tag_history" (
	"days_ago",
	"statuses"
) as (
	select			"date_part" (
					'days',
					(
						current_timestamp at time zone 'UTC'
					-	"created_at"
					)
				),
				count (*)
		from		"cache"."group_status_tags"
		where		"tag_id" = "in_tag_id"
			and	"group_id" = "in_group_id"
		group by	1
		order by	1
)
select			"t"."name",
			(
				"configuration"."base_url" ()
			||	'/tags/'
			||	"t"."name"
			),
			"array_agg" (
				(
					"d"."days_ago",
					"date_part" (
						'epoch',
						(
							current_date
						-	("d"."days_ago" || ' days')::interval
						)
					),
					coalesce ("h"."statuses", 0),
					0
				)::"mastodon_logic"."tag_history"
			),
			0
	from		"public"."tags" "t"
	cross join	"generate_series" (0, 5) "d" ("days_ago")
	left join	"tag_history" "h"
		on	"h"."days_ago" = "d"."days_ago"
	where		"t"."id" = "in_tag_id"
	group by	"t"."id"
$$;


--
-- Name: group_tags(bigint, bigint, smallint, integer); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.group_tags(in_account_id bigint, in_group_id bigint, in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS SETOF mastodon_logic.group_tag
    LANGUAGE sql STABLE
    AS $$
with "group_tags" (
	"tag_id",
	"group_tag_type",
	"uses",
	"accounts"
) as (
	select			"t"."tag_id",
				"t"."group_tag_type",
				coalesce ("c"."uses", 0),
				coalesce ("c"."accounts", 0)
		from		"public"."group_tags" "t"
		left join	"cache"."group_tag_uses" "c"
			using	(
					"group_id",
					"tag_id"
				)
		where		"t"."group_id" = "in_group_id"
			and	(
					"t"."group_tag_type" = 'pinned'
				or	exists (
						select			1
							from		"public"."groups" "g"
							where		"g"."id" = "t"."group_id"
								and	"g"."owner_account_id" = "in_account_id"
					)
				)
	union all
	select			"c"."tag_id",
				'normal',
				"uses",
				"accounts"
		from		"cache"."group_tag_uses" "c"
		where		"c"."group_id" = "in_group_id"
			and	not exists (
					select			1
						from		"public"."group_tags" "t"
						where		"t"."group_id" = "c"."group_id"
							and	"t"."tag_id" = "c"."tag_id"
				)
)
select			"g"."tag_id",
			"t"."name",
			"mastodon_logic"."tag_url" ("t"."name"),
			"g"."group_tag_type" = 'pinned',
			"g"."group_tag_type" <> 'hidden',
			"g"."uses",
			"g"."accounts"
	from		"group_tags" "g"
	join		"public"."tags" "t"
		on	"t"."id" = "g"."tag_id"
	order by	"g"."group_tag_type",
			"g"."accounts" desc,
			"t"."name"
	limit		"in_limit"
		offset	"in_offset"
$$;


--
-- Name: group_tags_simple(bigint); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.group_tags_simple(in_group_id bigint) RETURNS SETOF mastodon_logic.tag_simple
    LANGUAGE sql STABLE
    AS $$
select			"t"."name"
	from		"public"."tags" "t"
	join		"public"."group_tags" "g"
		on	"g"."tag_id" = "t"."id"
	where		"g"."group_id" = "in_group_id"
		and	"g"."group_tag_type" = 'pinned'
$$;


--
-- Name: group_url(text); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.group_url(in_slug text) RETURNS text
    LANGUAGE sql STABLE
    AS $$
select			(
				"configuration"."base_url" ()
			||	'/group/'
			||	"in_slug"
			)
$$;


--
-- Name: groups(bigint, boolean, text, smallint, integer); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.groups(in_account_id bigint, in_pending boolean DEFAULT false, in_search_query text DEFAULT NULL::text, in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS SETOF mastodon_logic."group"
    LANGUAGE sql STABLE
    AS $$
select			"g"."id",
			"g"."display_name",
			"mastodon_logic"."format_timestamp" ("g"."created_at"),
			row ("g"."owner_account_id")::"mastodon_logic"."group_owner",
			"mastodon_logic"."html_content" ("g"."note"),
			"mastodon_logic"."image_url" (
				'groups',
				'avatars',
				"g"."id",
				"g"."avatar_file_name"
			),
			"mastodon_logic"."image_static_url" (
				'groups',
				'avatars',
				"g"."id",
				"g"."avatar_file_name",
				"g"."avatar_content_type"
			),
			"mastodon_logic"."image_url" (
				'groups',
				'headers',
				"g"."id",
				"g"."header_file_name"
			),
			"mastodon_logic"."image_static_url" (
				'groups',
				'headers',
				"g"."id",
				"g"."header_file_name",
				"g"."header_content_type"
			),
			"g"."statuses_visibility",
			true,
			null,
			"g"."discoverable",
			"g"."locked",
			"s"."members_count",
			coalesce (
				(
				select			"array_agg" ("x")
					from		"mastodon_logic"."group_tags_simple" ("g"."id") "x"
				),
				array[]::"mastodon_logic"."tag_simple"[]
			),
			"g"."slug",
			"mastodon_logic"."group_url" ("g"."slug"),
			"mastodon_logic"."format_timestamp" ("g"."deleted_at"),
			row ("g"."note")::"mastodon_logic"."group_source"
	from		"public"."groups" "g"
	join		"public"."group_stats" "s"
		on	"s"."group_id" = "g"."id"
	left join	"public"."group_memberships" "m"
		on	"m"."group_id" = "g"."id"
		and	"m"."account_id" = "in_account_id"
	where		"g"."deleted_at" is null
		and	case
				when	"in_pending"
				then	exists (
						select			1
							from		"public"."group_membership_requests" "r"
							where		"r"."group_id" = "g"."id"
								and	"r"."account_id" = "in_account_id"
					)
				else	"m"."account_id" is not null
			end
		and	case
				when	"in_search_query" is not null
				then	(
						"g"."display_name" ilike '%' || "in_search_query" || '%'
					or	"g"."note" ilike '%' || "in_search_query" || '%'
					)
				else	true
			end
	order by	case
				when	(
						"g"."statuses_visibility" = 'members_only'
					and	"m"."role" in ('owner', 'admin')
					)
				then	(
						select			"max" ("r"."created_at")
							from		"public"."group_membership_requests" "r"
							where		"r"."group_id" = "g"."id"
					)
				else	null
			end desc nulls last,
			"mastodon_logic"."group_latest_activity" ("in_account_id", "g"."id") desc,
			"g"."id" desc
	limit		"in_limit"
		offset	"in_offset"
$$;


--
-- Name: groups_with_tag(text, smallint, integer); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.groups_with_tag(in_tag_name text, in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS SETOF mastodon_logic."group"
    LANGUAGE sql STABLE
    AS $$
select			"g"."id",
			"g"."display_name",
			"mastodon_logic"."format_timestamp" ("g"."created_at"),
			row ("g"."owner_account_id")::"mastodon_logic"."group_owner",
			"mastodon_logic"."html_content" ("g"."note"),
			"mastodon_logic"."image_url" (
				'groups',
				'avatars',
				"g"."id",
				"g"."avatar_file_name"
			),
			"mastodon_logic"."image_static_url" (
				'groups',
				'avatars',
				"g"."id",
				"g"."avatar_file_name",
				"g"."avatar_content_type"
			),
			"mastodon_logic"."image_url" (
				'groups',
				'headers',
				"g"."id",
				"g"."header_file_name"
			),
			"mastodon_logic"."image_static_url" (
				'groups',
				'headers',
				"g"."id",
				"g"."header_file_name",
				"g"."header_content_type"
			),
			"g"."statuses_visibility",
			true,
			null,
			"g"."discoverable",
			"g"."locked",
			"s"."members_count",
			coalesce (
				(
				select			"array_agg" ("x")
					from		"mastodon_logic"."group_tags_simple" ("g"."id") "x"
				),
				array[]::"mastodon_logic"."tag_simple"[]
			),
			"g"."slug",
			"mastodon_logic"."group_url" ("g"."slug"),
			"mastodon_logic"."format_timestamp" ("g"."deleted_at"),
			row ("g"."note")::"mastodon_logic"."group_source"
	from		"public"."groups" "g"
	join		"public"."group_stats" "s"
		on	"s"."group_id" = "g"."id"
	where		"g"."deleted_at" is null
		and	exists (
				select			1
					from		"cache"."group_tag_uses" "c"
					where		"c"."group_id" = "s"."group_id"
						and	"c"."tag_id" = "mastodon_logic"."tag_id" ("in_tag_name")
			)
	limit		"in_limit"
		offset	"in_offset"
$$;


--
-- Name: html_content(text); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.html_content(in_content text) RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
declare
	"var_line"		text;
	"var_link"		text;
	"var_match"		text;
	"var_matches"		text[];
	"var_output"		text;
	"var_output_line"	text;
	"var_regex_hashtag"	text;
	"var_regex_profile"	text;
	"var_regex_url"		text;
	"var_render_hashtag"	text;
	"var_render_profile"	text;
	"var_render_url"	text;
	"var_username"		text;
	"var_word"		text;
begin
	"var_regex_hashtag" :=	'#((?:[^\x00-\x7F]|[a-zA-Z0-9_])+)';
	"var_regex_profile" :=	'(@[A-Za-z0-9_]+)';
	"var_regex_url" :=	'(?<![@.,%&#-])((?:http|ftp|https):\/\/(?:(?:\w|\&\#\d{1,5};)[.-]?)+\.[a-z]{2,15}\/?(?:(?:[\w\d\?\-=#:%@&.;])+(?:\/(?:(?:[\w\d\?\-=#:%@&;.])+))*)?\/?)(?<![.,?!-])';
	"var_render_hashtag":=	(
					'<a class="mention hashtag" href="'
				||	"configuration"."base_url" ()
				||	'/tags/\1" rel="tag">#<span>\1</span></a>'
				);
	"var_render_profile" :=	(
					'<span class="h-card"><a class="u-url mention" href="'
				||	"configuration"."base_url" ()
				||	'/@\1">@<span>\1</span></a>'
				);
	"var_render_url" :=	'<a href="\1" rel="nofollow noopener" target="_blank">\1</a>';
	for "var_line" in
		select "regexp_split_to_table" ("in_content", '\n')
	loop
		for "var_word" in
			select "regexp_split_to_table" ("var_line", ' ')
		loop
			if "var_word" ~ "var_regex_url" then
				"var_word" := "replace" ("var_word", '<', '&lt;');
				"var_word" := "replace" ("var_word", '>', '&gt;');
				"var_matches" := "regexp_match" (
					"var_word",
					'(.+)?'||"var_regex_url"||'(.+)?'
				);
				select			"configuration"."link_url" ()||'/link/'||"id"
					into		"var_link"
					from		"public"."links"
					where		"url" = "var_matches"[2];
				if not found then
					"var_link" := "var_matches"[2];
				end if;
				"var_render_url" := '<a href="'||"var_link"||'" rel="nofollow noopener" target="_blank">\1</a>';
				"var_word" := "concat" (
					"replace" ("var_matches"[1], '&', '&amp;'),
					"regexp_replace" ("var_matches"[2], "var_regex_url", "var_render_url"),
					"replace" ("var_matches"[3], '&', '&amp;')
				);
			else
				"var_word" := "replace" ("var_word", '&', '&amp;');
				"var_word" := "replace" ("var_word", '<', '&lt;');
				"var_word" := "replace" ("var_word", '>', '&gt;');
				if "var_word" 	~ ('^'||"var_regex_hashtag") then
					"var_word" := "regexp_replace" ("var_word", "var_regex_hashtag", "var_render_hashtag");
				elsif "var_word" ~ ('^'||"var_regex_profile") then
					select			"right" ("match"[1], -1)
						into		"var_match"
						from		"regexp_match" ("var_word", "var_regex_profile") "r" ("match");
					select			"username"
						into		"var_username"
						from		"public"."accounts"
						where		"lower" ("username") = "lower" ("var_match");
					if found then
						"var_word" := "replace" ("var_word", '@'||"var_match", '@'||"var_username");
						"var_word" := "regexp_replace" ("var_word", '@('||"var_match"||')', "var_render_profile");
					end if;
				end if;
			end if;
			if "var_output_line" is null then
				"var_output_line" := "var_word";
			else
				"var_output_line" := "var_output_line"||' '||"var_word";
			end if;
		end loop;
		"var_output_line" := "replace" ("var_output_line", '  ', ' &nbsp;');
		if "var_output" is null then
			"var_output" := "var_output_line";
		else
			"var_output" := "var_output"||E'\n'||"var_output_line";
		end if;
		"var_output_line" := null;
	end loop;
	"var_output" := '<p>'||"var_output"||'</p>';
	"var_output" := "regexp_replace" ("var_output", E'\n\n+', '</p><p>', 'g');
	"var_output" := "regexp_replace" ("var_output", E'\n', '<br/>', 'g');
	return "var_output";
end
$$;


--
-- Name: image_static_url(text, text, bigint, text, public.image_content_type); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.image_static_url(in_object_type text, in_image_type text, in_object_id bigint, in_file_name text, in_content_type public.image_content_type) RETURNS text
    LANGUAGE sql STABLE
    AS $_$
select			coalesce (
				(
					"configuration"."storage_base_url" ()
				||	'/'
				||	"in_object_type"
				||	'/'
				||	"in_image_type"
				||	'/'
				||	to_char (
						"in_object_id",
						'FM999/999/999/999/999/999'
					)
				||	'/'
				||	case
						when	"in_content_type" = 'image/gif'
						then	'static'
						else	'original'
					end
				||	'/'
				||	regexp_replace (
						"in_file_name",
						'.gif$',
						'.png'
					)
				),
				(
					"configuration"."base_url" ()
				||	'/'
				||	"in_object_type"
				||	'/'
				||	"in_image_type"
				||	'/original/missing.png'
				)
			)
$_$;


--
-- Name: image_url(text, text, bigint, text); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.image_url(in_object_type text, in_image_type text, in_object_id bigint, in_file_name text) RETURNS text
    LANGUAGE sql STABLE
    AS $$
select			coalesce (
				(
					"configuration"."storage_base_url" ()
				||	'/'
				||	"in_object_type"
				||	'/'
				||	"in_image_type"
				||	'/'
				||	to_char (
						"in_object_id",
						'FM999/999/999/999/999/999'
					)
				||	'/original/'
				||	"in_file_name"
				),
				(
					"configuration"."base_url" ()
				||	'/'
				||	"in_object_type"
				||	'/'
				||	"in_image_type"
				||	'/original/missing.png'
				)
			)
$$;


--
-- Name: poll_options(bigint); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.poll_options(in_poll_id bigint) RETURNS SETOF mastodon_logic.poll_option
    LANGUAGE sql STABLE
    AS $$
select			"o"."text",
			coalesce (
				"s"."votes",
				0
			)
	from		"polls"."options" "o"
	left join	"statistics"."poll_options" "s"
		using	(
				"poll_id",
				"option_number"
			)
	where		"o"."poll_id" = "in_poll_id"
$$;


--
-- Name: popular_group_tags(smallint, integer); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.popular_group_tags(in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS SETOF mastodon_logic.popular_group_tag
    LANGUAGE sql STABLE
    AS $$
select			"c"."tag_id",
			"t"."name",
			"mastodon_logic"."tag_url" ("t"."name"),
			count (distinct "c"."group_id")
	from		"cache"."group_tag_uses" "c"
	join		"public"."tags" "t"
		on	"t"."id" = "c"."tag_id"
	group by	1, 2, 3
	order by	sum ("c"."accounts") desc,
			"c"."tag_id"
	limit		"in_limit"
		offset	"in_offset"
$$;


--
-- Name: search_tags(text, smallint, integer); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.search_tags(in_search_query text, in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS SETOF mastodon_logic.tag_statistics
    LANGUAGE plpgsql STABLE
    AS $$
declare
	"var_result"		"mastodon_logic"."tag_statistics";
	"var_search_query"	text;
	"var_tag_id"		int8;
begin
	"var_search_query" := "regexp_replace" ("in_search_query", '^#*', '');
	if "length" ("var_search_query") > 0 then
		for "var_tag_id" in (
			select			"t"."id"
				from		"public"."tags" "t"
				left join	"cache"."tag_uses" "u"
					on	"u"."tag_id" = "t"."id"
				where		"t"."name" ilike '%' || "var_search_query" || '%'
					and	"t"."listable" is not false
				order by	"t"."name" ilike "var_search_query" desc,
						"u"."uses" desc nulls last
				limit		"in_limit"
					offset	"in_offset"
		) loop
			"var_result" := "mastodon_logic"."tag_statistics" ("var_tag_id");
			return next "var_result";
		end loop;
	end if;
end
$$;


--
-- Name: status_poll(bigint, bigint); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.status_poll(in_account_id bigint, in_status_id bigint) RETURNS SETOF mastodon_logic.poll
    LANGUAGE sql
    AS $$
select			"p"."poll_id",
			"mastodon_logic"."format_timestamp" ("p"."expires_at"),
			"p"."expires_at" < current_timestamp,
			"p"."multiple_choice",
			coalesce (
				"s"."votes",
				0
			),
			coalesce (
				"s"."voters",
				0
			),
			exists (
				select			1
					from		"polls"."votes" "v"
					where		"v"."poll_id" = "p"."poll_id"
						and	"v"."account_id" = "in_account_id"
			),
			(
				select			"array_agg" (
								"option_number"
								order by "option_number"
							)
					from		"polls"."votes" "v"
					where		"v"."poll_id" = "p"."poll_id"
						and	"v"."account_id" = "in_account_id"
			),
			(
				select			"array_agg" ("x")
					from		"mastodon_logic"."poll_options" ("p"."poll_id") "x"
			)
	from		"polls"."polls" "p"
	left join	"statistics"."polls" "s"
		using	("poll_id")
	where		exists (
				select			1
					from		"polls"."status_polls" "x"
					where		"x"."poll_id" = "p"."poll_id"
						and	"x"."status_id" = "in_status_id"
			)
$$;


--
-- Name: status_replies(bigint, bigint, mastodon_logic.status_reply_sort_order, smallint, integer); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.status_replies(in_account_id bigint, in_status_id bigint, in_sort_order mastodon_logic.status_reply_sort_order DEFAULT 'trending'::mastodon_logic.status_reply_sort_order, in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS SETOF bigint
    LANGUAGE sql STABLE
    AS $$
with "top_level_replies" (
	"status_id",
	"sort_order"
) as (
	select			"status_id",
				"sort_order"
		from		"mastodon_logic"."status_top_level_replies" (
					"in_account_id",
					"in_status_id",
					"in_sort_order",
					"in_limit",
					"in_offset"
				)
),
"author_replies" (
	"author_reply_status_id",
	"top_level_status_id",
	"sort_order"
) as (
	select			distinct on ("r"."status_id")
				"s"."id",
				"r"."status_id",
				"r"."sort_order"
		from		"top_level_replies" "r"
		join		"public"."statuses" "s"
			on	"s"."in_reply_to_id" = "r"."status_id"
			and	"s"."account_id" = (
					select			"account_id"
						from		"public"."statuses"
						where		"id" = "in_status_id"
				)
			and	"s"."deleted_at" is null
		order by	"r"."status_id",
				"s"."created_at"
)
select			"status_id"
	from		(
				select			"status_id",
							"status_id",
							"sort_order"
					from		"top_level_replies"
				union all
				select			"author_reply_status_id",
							"top_level_status_id",
							"sort_order"
					from		"author_replies"
			) "s" (
				"status_id",
				"top_level_status_id"
			)
order by		"sort_order",
			("status_id" = "top_level_status_id") desc;
$$;


--
-- Name: status_top_level_replies(bigint, bigint, mastodon_logic.status_reply_sort_order, smallint, integer); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.status_top_level_replies(in_account_id bigint, in_status_id bigint, in_sort_order mastodon_logic.status_reply_sort_order DEFAULT 'trending'::mastodon_logic.status_reply_sort_order, in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS SETOF mastodon_logic.status_top_level_reply
    LANGUAGE plpgsql STABLE
    AS $$
begin
	case "in_sort_order"
		when 'oldest' then
			return query (
				select			"s"."id",
							"row_number" () over ()::int4
					from		"public"."statuses" "s"
					where		"s"."in_reply_to_id" = "in_status_id"
						and	"s"."deleted_at" is null
						and	not exists (
								select			1
									from		"public"."accounts" "a"
									where		"a"."id" = "s"."account_id"
										and	"a"."suspended_at" is not null
							)
						and	not exists (
								select			1
									from		"public"."blocks" "b"
									where		"b"."account_id" = "s"."account_id"
										and	"b"."target_account_id" = "in_account_id"
										and	not exists (
												select			1
													from		"public"."group_memberships" "m"
													where		"m"."group_id" = "s"."group_id"
														and	"m"."account_id" = "in_account_id"
														and	"m"."role" in (
																'owner',
																'admin'
															)
											)
							)
						and	not exists (
								select			1
									from		"public"."blocks" "b"
									where		"b"."account_id" = "in_account_id"
										and	"b"."target_account_id" = "s"."account_id"
							)
						and	not exists (
								select			1
									from		"public"."mutes" "m"
									where		"m"."account_id" = "in_account_id"
										and	"m"."target_account_id" = "s"."account_id"
							)
					order by	"s"."created_at"
					limit		"in_limit"
					offset		"in_offset"
			);
		when 'newest' then
			return query (
				select			"s"."id",
							"row_number" () over ()::int4
					from		"public"."statuses" "s"
					where		"s"."in_reply_to_id" = "in_status_id"
						and	"s"."deleted_at" is null
						and	not exists (
								select			1
									from		"public"."accounts" "a"
									where		"a"."id" = "s"."account_id"
										and	"a"."suspended_at" is not null
							)
						and	not exists (
								select			1
									from		"public"."blocks" "b"
									where		"b"."account_id" = "s"."account_id"
										and	"b"."target_account_id" = "in_account_id"
										and	not exists (
												select			1
													from		"public"."group_memberships" "m"
													where		"m"."group_id" = "s"."group_id"
														and	"m"."account_id" = "in_account_id"
														and	"m"."role" in (
																'owner',
																'admin'
															)
											)
							)
						and	not exists (
								select			1
									from		"public"."blocks" "b"
									where		"b"."account_id" = "in_account_id"
										and	"b"."target_account_id" = "s"."account_id"
							)
						and	not exists (
								select			1
									from		"public"."mutes" "m"
									where		"m"."account_id" = "in_account_id"
										and	"m"."target_account_id" = "s"."account_id"
							)
					order by	"s"."created_at" desc
					limit		"in_limit"
					offset		"in_offset"
			);
		when 'trending' then
			return query (
				select			"s"."id",
							"row_number" () over ()::int4
					from		"public"."statuses" "s"
					join		"statistics"."reply_status_trending_scores" "t"
						on	"t"."status_id" = "s"."id"
					where		"t"."reply_to_status_id" = "in_status_id"
						and	not exists (
								select			1
									from		"public"."accounts" "a"
									where		"a"."id" = "s"."account_id"
										and	"a"."suspended_at" is not null
							)
						and	not exists (
								select			1
									from		"public"."blocks" "b"
									where		"b"."account_id" = "s"."account_id"
										and	"b"."target_account_id" = "in_account_id"
										and	not exists (
												select			1
													from		"public"."group_memberships" "m"
													where		"m"."group_id" = "s"."group_id"
														and	"m"."account_id" = "in_account_id"
														and	"m"."role" in (
																'owner',
																'admin'
															)
											)
							)
						and	not exists (
								select			1
									from		"public"."blocks" "b"
									where		"b"."account_id" = "in_account_id"
										and	"b"."target_account_id" = "s"."account_id"
							)
						and	not exists (
								select			1
									from		"public"."mutes" "m"
									where		"m"."account_id" = "in_account_id"
										and	"m"."target_account_id" = "s"."account_id"
							)
					order by	"t"."score" desc
					limit		"in_limit"
					offset		"in_offset"
			);
		when 'controversial' then
			return query (
				select			"s"."id",
							"row_number" () over ()::int4
					from		"public"."statuses" "s"
					join		"statistics"."reply_status_controversial_scores" "c"
						on	"c"."status_id" = "s"."id"
					where		"c"."reply_to_status_id" = "in_status_id"
						and	not exists (
								select			1
									from		"public"."accounts" "a"
									where		"a"."id" = "s"."account_id"
										and	"a"."suspended_at" is not null
							)
						and	not exists (
								select			1
									from		"public"."blocks" "b"
									where		"b"."account_id" = "s"."account_id"
										and	"b"."target_account_id" = "in_account_id"
										and	not exists (
												select			1
													from		"public"."group_memberships" "m"
													where		"m"."group_id" = "s"."group_id"
														and	"m"."account_id" = "in_account_id"
														and	"m"."role" in (
																'owner',
																'admin'
															)
											)
							)
						and	not exists (
								select			1
									from		"public"."blocks" "b"
									where		"b"."account_id" = "in_account_id"
										and	"b"."target_account_id" = "s"."account_id"
							)
						and	not exists (
								select			1
									from		"public"."mutes" "m"
									where		"m"."account_id" = "in_account_id"
										and	"m"."target_account_id" = "s"."account_id"
							)
					order by	"c"."score" desc
					limit		"in_limit"
					offset		"in_offset"
			);
	end case;
end
$$;


--
-- Name: tag_id(text); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.tag_id(in_tag_name text) RETURNS bigint
    LANGUAGE sql STABLE
    AS $$
select			"id"
	from		"public"."tags"
	where		"lower" ("name") = "lower" ("in_tag_name")
$$;


--
-- Name: tag_statistics(bigint); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.tag_statistics(in_tag_id bigint) RETURNS mastodon_logic.tag_statistics
    LANGUAGE sql STABLE
    AS $$
with "tag_history" (
	"days_ago",
	"statuses",
	"accounts"
) as (
		select		"d"."days_ago",
				count ("c"."status_id"),
				count (distinct "c"."account_id")
		from		"generate_series" (0, 6) "d" ("days_ago")
		left join	"cache"."status_tags" "c"
			on	"date_part" (
					'days',
					(
						current_timestamp
					-	"c"."created_at"
					)
				) = "d"."days_ago"
			and	"c"."tag_id" = "in_tag_id"
		group by	1
		order by	1 desc
)
select			"common_logic"."tag_name" ("in_tag_id"),
			(
				"configuration"."base_url" ()
			||	'/tags/'
			||	"common_logic"."tag_name" ("in_tag_id")
			),
			"array_agg" (
				(
					"days_ago",
					"date_part" (
						'epoch',
						(
							current_date
						-	("days_ago" || ' days')::interval
						)
					),
					"statuses",
					"accounts"
				)::"mastodon_logic"."tag_history"
				order by	"days_ago"
			),
			(
				select			sum ("statuses")
					from		"tag_history"
			),
			(
				select			"array_agg" (
								coalesce ("accounts", 0)
							)
					from		"tag_history"
			)
	from		"tag_history"
	group by	1
$$;


--
-- Name: tag_url(text); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.tag_url(in_tag_name text) RETURNS text
    LANGUAGE sql STABLE
    AS $$
select			(
				"configuration"."base_url" ()
			||	'/tags/'
			||	"in_tag_name"
			)
$$;


--
-- Name: trending_groups(bigint, smallint, integer); Type: FUNCTION; Schema: mastodon_logic; Owner: -
--

CREATE FUNCTION mastodon_logic.trending_groups(in_account_id bigint DEFAULT NULL::bigint, in_limit smallint DEFAULT 20, in_offset integer DEFAULT 0) RETURNS SETOF mastodon_logic."group"
    LANGUAGE sql STABLE
    AS $$
select			"g"."id",
			"g"."display_name",
			"mastodon_logic"."format_timestamp" ("g"."created_at"),
			row ("g"."owner_account_id")::"mastodon_logic"."group_owner",
			"mastodon_logic"."html_content" ("g"."note"),
			"mastodon_logic"."image_url" (
				'groups',
				'avatars',
				"g"."id",
				"g"."avatar_file_name"
			),
			"mastodon_logic"."image_static_url" (
				'groups',
				'avatars',
				"g"."id",
				"g"."avatar_file_name",
				"g"."avatar_content_type"
			),
			"mastodon_logic"."image_url" (
				'groups',
				'headers',
				"g"."id",
				"g"."header_file_name"
			),
			"mastodon_logic"."image_static_url" (
				'groups',
				'headers',
				"g"."id",
				"g"."header_file_name",
				"g"."header_content_type"
			),
			"g"."statuses_visibility",
			true,
			null,
			"g"."discoverable",
			"g"."locked",
			"s"."members_count",
			coalesce (
				(
				select			"array_agg" ("x")
					from		"mastodon_logic"."group_tags_simple" ("g"."id") "x"
				),
				array[]::"mastodon_logic"."tag_simple"[]
			),
			"g"."slug",
			"mastodon_logic"."group_url" ("g"."slug"),
			"mastodon_logic"."format_timestamp" ("g"."deleted_at"),
			row ("g"."note")::"mastodon_logic"."group_source"
	from		"public"."groups" "g"
	join		"public"."group_stats" "s"
		on	"s"."group_id" = "g"."id"
	join		"trending_groups"."trending_group_scores" "c"
		on	"c"."group_id" = "g"."id"
	where		"g"."deleted_at" is null
		and	not (
				"in_account_id" is not null
			and	exists (
					select			1
						from		"public"."group_memberships" "m"
						where		"m"."group_id" = "c"."group_id"
							and	"m"."account_id" = "in_account_id"
					union all
					select			1
						from		"public"."group_membership_requests" "r"
						where		"r"."group_id" = "c"."group_id"
							and	"r"."account_id" = "in_account_id"
					union all
					select			1
						from		"public"."group_account_blocks" "b"
						where		"b"."group_id" = "c"."group_id"
							and	"b"."account_id" = "in_account_id"
				)
			)
		and	not exists (
				select			1
					from		"trending_groups"."excluded_groups" "x"
					where		"x"."group_id" = "g"."id"
			)
	order by	"c"."score" desc,
			"g"."id" desc
	limit		"in_limit"
		offset	"in_offset"
$$;


--
-- Name: orphaned_media_attachments(); Type: FUNCTION; Schema: mastodon_media_api; Owner: -
--

CREATE FUNCTION mastodon_media_api.orphaned_media_attachments() RETURNS SETOF mastodon_media_api.media_attachment
    LANGUAGE sql STABLE
    AS $$
select			"a"."id",
			"a"."status_id",
			"a"."file_file_name",
			"a"."file_content_type",
			"a"."file_file_size",
			"a"."file_updated_at",
			"a"."remote_url",
			"a"."created_at",
			"a"."updated_at",
			"a"."shortcode",
			"a"."type",
			"a"."file_meta",
			"a"."account_id",
			"a"."description",
			"a"."scheduled_status_id",
			"a"."blurhash",
			"a"."processing",
			"a"."file_storage_schema_version",
			"a"."thumbnail_file_name",
			"a"."thumbnail_content_type",
			"a"."thumbnail_file_size",
			"a"."thumbnail_updated_at",
			"a"."thumbnail_remote_url",
			"a"."external_video_id",
			"a"."file_s3_host"
	from		"public"."media_attachments" "a"
	where		"a"."status_id" is null
		and	"a"."scheduled_status_id" is null
		and	not exists (
				select			1
					from		"chats"."message_media_attachments" "m"
					where		"m"."media_attachment_id" = "a"."id"
			)
		and	"a"."created_at" < current_timestamp - interval '1 day'
$$;


--
-- Name: prune_notifications(); Type: PROCEDURE; Schema: notifications; Owner: -
--

CREATE PROCEDURE notifications.prune_notifications()
    LANGUAGE plpgsql
    AS $_$
declare
	"var_partition"		text := 'part_' || (("floor" ("date_part" ('julian', current_date + interval '1 week'))::int / 7 % 6) + 1)::text;
begin
	execute "format" (
		$sql$truncate "notifications".%I$sql$,
		"var_partition"
	);
end
$_$;


--
-- Name: disallow_group_owner_membership_deletions(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.disallow_group_owner_membership_deletions() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	perform			1
		from		"old_data"
		where		"role" = 'owner'
		limit		1;
	if found then
		raise exception 'Cannot delete group membership record for group owner!';
	end if;
	return null;
end
$$;


--
-- Name: notifications_sync(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.notifications_sync() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"public"."notifications_weekly" (
					"id",
					"activity_id",
					"activity_type",
					"created_at",
					"updated_at",
					"account_id",
					"from_account_id",
					"type",
					"count"
				)
		values		(
					"new"."id",
					"new"."activity_id",
					"new"."activity_type",
					"new"."created_at",
					"new"."updated_at",
					"new"."account_id",
					"new"."from_account_id",
					"new"."type",
					"new"."count"
				);
	return "new";
end
$$;


--
-- Name: timestamp_id(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.timestamp_id(table_name text) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
  DECLARE
    time_part bigint;
    sequence_base bigint;
    tail bigint;
  BEGIN
    time_part := (
      -- Get the time in milliseconds
      ((date_part('epoch', now()) * 1000))::bigint
      -- And shift it over two bytes
      << 16);

    sequence_base := (
      'x' ||
      -- Take the first two bytes (four hex characters)
      substr(
        -- Of the MD5 hash of the data we documented
        md5(table_name ||
          'f3686705c8cc5ecf2cc2344555172dae' ||
          time_part::text
        ),
        1, 4
      )
    -- And turn it into a bigint
    )::bit(16)::bigint;

    -- Finally, add our sequence number to our base, and chop
    -- it to the last two bytes
    tail := (
      (sequence_base + nextval(table_name || '_id_seq'))
      & 65535);

    -- Return the time part and the sequence part. OR appears
    -- faster here than addition, but they're equivalent:
    -- time_part has no trailing two bytes, and tail is only
    -- the last two bytes.
    RETURN time_part | tail;
  END
$$;


--
-- Name: update_group(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_group() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if "new"."id" <> "old"."id" then
		raise exception 'Group ID cannot be changed!';
	end if;
	if "new" is distinct from "old" then
		"new"."updated_at" = current_timestamp at time zone 'UTC';
	end if;
	return "new";
end
$$;


--
-- Name: create_reply_status_scores(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.create_reply_status_scores() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"statistics"."reply_status_trending_scores" (
					"status_id",
					"reply_to_status_id"
				)
		values		(
					"new"."id",
					"new"."in_reply_to_id"
				);
	insert into		"statistics"."reply_status_controversial_scores" (
					"status_id",
					"reply_to_status_id"
				)
		values		(
					"new"."id",
					"new"."in_reply_to_id"
				);
	return null;
end
$$;


--
-- Name: queue_account_index_refresh(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.queue_account_index_refresh() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
	"var_account_id"	int8;
	"var_dirty_fields"	text[];
	"var_column_whitelist"	text[];
begin
	select			case
					when	(
							"tg_table_schema" = 'public'
						and	"tg_table_name" = 'accounts'
						)
					then	array[
							'display_name',
							'username',
							'suspended_at',
							'avatar_file_name',
							'header_file_name',
							'website',
							'note',
							'location',
							'verified',
							'created_at'
						]
					when	(
							"tg_table_schema" = 'public'
						and	"tg_table_name" = 'users'
						)
					then	array[
							'disabled',
							'email',
							'last_sign_in_ip',
							'admin',
							'moderator',
							'sms'
						]
					when	(
							"tg_table_schema" = 'statistics'
						and	"tg_table_name" = 'account_followers'
						)
					then	array['followers_count']
					when	(
							"tg_table_schema" = 'statistics'
						and	"tg_table_name" = 'account_following'
						)
					then	array['following_count']
					when	(
							"tg_table_schema" = 'statistics'
						and	"tg_table_name" = 'account_statuses'
						)
					then	array[
							'last_status_at',
							'statuses_count'
						]
				end
		into		"var_column_whitelist";
	select			"array_agg" ("k"."column_name")
		into		"var_dirty_fields"
		from		"unnest" (
					"akeys" (
						"hstore" ("new")
					-	"hstore" ("old")
					)
				) "k" ("column_name")
		join		"unnest" (
					"var_column_whitelist"
				) "x" ("column_name")
			using	("column_name");
	if "tg_op" <> 'DELETE' then

		if "tg_table_schema" = 'public' and "tg_table_name" = 'accounts' then
			"var_account_id" := "new"."id";
		else
			"var_account_id" := "new"."account_id";
		end if;
	else
		if "tg_table_schema" = 'public' and "tg_table_name" = 'accounts' then
			"var_account_id" := "old"."id";
		else
			"var_account_id" := "old"."account_id";
		end if;
	end if;
	insert into		"queues"."account_index_1" (
					"account_id",
					"dirty_fields"
				)
		values		(
					"var_account_id",
					"var_dirty_fields"
				);
	insert into		"queues"."account_index_2" (
					"account_id",
					"dirty_fields"
				)
		values		(
					"var_account_id",
					"var_dirty_fields"
				);
	return null;
end
$$;


--
-- Name: queue_status_index_refresh(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.queue_status_index_refresh() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
	"var_status_id"		int8;
begin
	if "tg_op" <> 'DELETE' then
		if "tg_table_schema" = 'public' then
			"var_status_id" := "new"."id";
		else
			"var_status_id" := "new"."status_id";
		end if;
	else
		if "tg_table_schema" = 'public' then
			"var_status_id" := "old"."id";
		else
			"var_status_id" := "old"."status_id";
		end if;
	end if;
  insert into		"queues"."status_index_1" ( "status_id" ) values ( "var_status_id" );
  insert into		"queues"."status_index_2" ( "status_id" ) values ( "var_status_id" );
	return null;
end
$$;


--
-- Name: queue_tag_index_refresh(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.queue_tag_index_refresh() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
	"var_tag_id"		int8;
begin
	if "tg_op" <> 'DELETE' then
		"var_tag_id" := "new"."id";
	else
		"var_tag_id" := "old"."id";
	end if;
  insert into		"queues"."tag_index_1" ( "tag_id" ) values ( "var_tag_id" );
  insert into		"queues"."tag_index_2" ( "tag_id" ) values ( "var_tag_id" );
	return null;
end
$$;


--
-- Name: send_notification(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.send_notification() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	execute 'notify '||"quote_ident" ("tg_argv"[0]);
	return null;
end
$$;


--
-- Name: update_account_follow_statistics_after_delete(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_account_follow_statistics_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."account_following_statistics" (
					"account_id",
					"adjustment"
				)
	select			"account_id",
				count (1) * -1
		from		"old_data"
		group by	1
		having		count (1) <> 0;
	insert into		"queues"."account_follower_statistics" (
					"account_id",
					"adjustment"
				)
	select			"target_account_id",
				count (1) * -1
		from		"old_data"
		group by	1
		having		count (1) <> 0;
	return null;
end
$$;


--
-- Name: update_account_follow_statistics_after_insert(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_account_follow_statistics_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."account_following_statistics" (
					"account_id",
					"adjustment"
				)
	select			"account_id",
				count (1)
		from		"new_data"
		group by	1
		having		count (1) <> 0;
	insert into		"queues"."account_follower_statistics" (
					"account_id",
					"adjustment"
				)
	select			"target_account_id",
				count (1)
		from		"new_data"
		group by	1
		having		count (1) <> 0;
	return null;
end
$$;


--
-- Name: update_account_follow_statistics_after_update(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_account_follow_statistics_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	with "changed_accounts" as (
		select			"o"."account_id" "old_account_id",
					"n"."account_id" "new_account_id"
			from		"old_data" "o"
			join		"new_data" "n"
				using	("id")
			where		"n"."account_id" <> "o"."account_id"
	)
	insert into		"queues"."account_following_statistics" (
					"account_id",
					"adjustment"
				)
	select			"old_account_id",
				count (1) * -1
		from		"changed_accounts"
		group by	1
		having		count (1) <> 0
	union all
	select			"new_account_id",
				count (1)
		from		"changed_accounts"
		group by	1
		having		count (1) <> 0;
	with "changed_accounts" as (
		select			"o"."target_account_id" "old_account_id",
					"n"."target_account_id" "new_account_id"
			from		"old_data" "o"
			join		"new_data" "n"
				using	("id")
			where		"n"."target_account_id" <> "o"."target_account_id"
	)
	insert into		"queues"."account_follower_statistics" (
					"account_id",
					"adjustment"
				)
	select			"old_account_id",
				count (1) * -1
		from		"changed_accounts"
		group by	1
		having		count (1) <> 0
	union all
	select			"new_account_id",
				count (1)
		from		"changed_accounts"
		group by	1
		having		count (1) <> 0;
	return null;
end
$$;


--
-- Name: update_account_status_statistics_after_delete(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_account_status_statistics_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	with "statistics" as (
		select			"account_id",
					count (1) * -1 "adjustment"
			from		"old_data"
			where		"deleted_at" is null
				and	"visibility" in (0, 6)
			group by	1
				having	count (1) <> 0
	)
	insert into		"queues"."account_status_statistics" (
					"account_id",
					"adjustment"
				)
	select			"s"."account_id",
				"s"."adjustment"
		from		"statistics" "s";
	return null;
end
$$;


--
-- Name: update_account_status_statistics_after_insert(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_account_status_statistics_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
	"var_adjustment"	smallint;
begin
	insert into		"queues"."account_status_statistics" (
					"account_id",
					"adjustment"
				)
	select			"account_id",
				count (1)
		from		"new_data"
		where		"deleted_at" is null
			and	"visibility" in (0, 6)
		group by	1
			having	count (1) <> 0;
	return null;
end
$$;


--
-- Name: update_account_status_statistics_after_update(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_account_status_statistics_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	with "statistics" (
		"account_id",
		"adjustment"
	) as (
		select			"n"."account_id",
					sum (
						case	when	(
									"o"."deleted_at" is null
								and	"o"."visibility" in (0, 6)
								)
							and	not (
									"n"."deleted_at" is null
								and	"n"."visibility" in (0, 6)
								)
							then	-1
							when	not (
									"o"."deleted_at" is null
								and	"o"."visibility" in (0, 6)
								)
							and	(
									"n"."deleted_at" is null
								and	"n"."visibility" in (0, 6)
								)
							then	1
							else	0
						end
					)
			from		"old_data" "o"
			join		"new_data" "n"
				using	("id")
			group by	1
	)
	insert into		"queues"."account_status_statistics" (
					"account_id",
					"adjustment"
				)
	select			"account_id",
				"adjustment"
		from		"statistics"
		where		"adjustment" <> 0;
	return null;
end
$$;


--
-- Name: update_chat_subscriber_counts_after_member_delete(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_chat_subscriber_counts_after_member_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_subscribers" (
					"chat_id",
					"adjustment"
				)
	select			"o"."chat_id",
				count (1) * -1
		from		"old_data" "o"
		where		exists (
					select			1
						from		"chats"."chats" "c"
						where		"c"."chat_id" = "o"."chat_id"
							and	"c"."chat_type" = 'channel'
				)
			and	"o"."accepted"
			and	"o"."active"
		group by	1
		having		count (1) <> 0;
	return null;
end
$$;


--
-- Name: update_chat_subscriber_counts_after_member_insert(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_chat_subscriber_counts_after_member_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_subscribers" (
					"chat_id",
					"adjustment"
				)
	select			"n"."chat_id",
				count (1)
		from		"new_data" "n"
		where		exists (
					select			1
						from		"chats"."chats" "c"
						where		"c"."chat_id" = "n"."chat_id"
							and	"c"."chat_type" = 'channel'
				)
			and	"n"."accepted"
			and	"n"."active"
		group by	1
		having		count (1) <> 0;
	return null;
end
$$;


--
-- Name: update_chat_subscriber_counts_after_member_update(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_chat_subscriber_counts_after_member_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."chat_subscribers" (
					"chat_id",
					"adjustment"
				)
	select			"n"."chat_id",
				sum (
					case
						when	(
								(
									not "o"."accepted"
								or	not "o"."active"
								)
							and	"n"."accepted"
							and	"n"."active"
							)
						then	1
						when	(
								"o"."accepted"
							and	"o"."active"
							and	(
									not "n"."accepted"
								or	not "n"."active"
								)
							)
						then	-1
					end
				)
		from		"old_data" "o"
		join		"new_data" "n"
			using	(
					"chat_id",
					"account_id"
				)
		where		exists (
					select			1
						from		"chats"."chats" "c"
						where		"c"."chat_id" = "n"."chat_id"
							and	"c"."chat_type" = 'channel'
				)
			and	(
					(
						(
							not "o"."accepted"
						or	not "o"."active"
						)
					and	"n"."accepted"
					and	"n"."active"
					)
				or	(
						"o"."accepted"
					and	"o"."active"
					and	(
							not "n"."accepted"
						or	not "n"."active"
						)
					)
				)
		group by	1;
	return null;
end
$$;


--
-- Name: update_poll_option_statistics_after_delete(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_poll_option_statistics_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."poll_option_statistics" (
					"poll_id",
					"option_number",
					"adjustment"
				)
	select			"poll_id",
				"option_number",
				count (1) * -1
		from		"old_data"
		group by	1, 2
		having		count (1) <> 0;
	return null;
end
$$;


--
-- Name: update_poll_option_statistics_after_insert(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_poll_option_statistics_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."poll_option_statistics" (
					"poll_id",
					"option_number",
					"adjustment"
				)
	select			"poll_id",
				"option_number",
				count (1)
		from		"new_data"
		group by	1, 2
		having		count (1) <> 0;
	return null;
end
$$;


--
-- Name: update_reply_status_controversial_scores(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_reply_status_controversial_scores() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."reply_status_controversial_scores" ("status_id")
	select			"d"."status_id"
		from		"data" "d"
		where		exists (
					select			1
						from		"public"."statuses" "s"
						where		"s"."id" = "d"."status_id"
							and	"in_reply_to_id" is not null
				);
	if (
		"tg_table_schema" = 'statistics'
	and	"tg_table_name" in (
			'status_replies',
			'status_reblogs'
		)
	) then
		insert into		"queues"."reply_status_controversial_scores" ("status_id")
		select			"p"."id"
			from		"public"."statuses" "p"
			where		exists (
						select			1
							from		"data" "d"
							join		"public"."statuses" "s"
								on	"s"."id" = "d"."status_id"
							where		"s"."in_reply_to_id" = "p"."id"
					)
				and	"p"."in_reply_to_id" is not null;
	end if;
	return null;
end
$$;


--
-- Name: update_reply_status_controversial_scores_for_each_row(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_reply_status_controversial_scores_for_each_row() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
	"var_reply_to_status_id"	int8;
begin
	select			"in_reply_to_id"
		into		"var_reply_to_status_id"
		from		"public"."statuses"
		where		"id" = "new"."status_id"
			and	"in_reply_to_id" is not null;
	if found then
		insert into		"queues"."reply_status_controversial_scores" ("status_id")
			values		("new"."status_id"),
					("var_reply_to_status_id");
	end if;
	return null;
end
$$;


--
-- Name: update_reply_status_trending_scores(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_reply_status_trending_scores() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."reply_status_trending_scores" ("status_id")
	select			"d"."status_id"
		from		"data" "d"
		where		exists (
					select			1
						from		"public"."statuses" "s"
						where		"s"."id" = "d"."status_id"
							and	"in_reply_to_id" is not null
				);
	return null;
end
$$;


--
-- Name: update_status_engagement_statistics(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_status_engagement_statistics() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."status_engagement_statistics" ("status_id")
	select			"d"."status_id"
		from		"data" "d";
	return null;
end
$$;


--
-- Name: update_status_favourite_statistics_after_delete(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_status_favourite_statistics_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."status_favourite_statistics" (
					"status_id",
					"adjustment"
				)
	select			"status_id",
				count (1) * -1
		from		"old_data"
		group by	1
			having	count (1) <> 0;
	return null;
end
$$;


--
-- Name: update_status_favourite_statistics_after_insert(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_status_favourite_statistics_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."status_favourite_statistics" (
					"status_id",
					"adjustment"
				)
	select			"status_id",
				count (1)
		from		"new_data"
		group by	1
			having	count (1) <> 0;
	return null;
end
$$;


--
-- Name: update_status_favourite_statistics_after_update(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_status_favourite_statistics_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	with "changed_favourites" (
		"old_status_id",
		"new_status_id"
	) as (
		select			"o"."status_id",
					"n"."status_id"
			from		"old_data" "o"
			join		"new_data" "n"
				using	("id")
			where		"n"."status_id" <> "o"."status_id"
	)
	insert into		"queues"."status_favourite_statistics" (
					"status_id",
					"adjustment"
				)
	select			"old_status_id",
				count (1) * -1
		from		"changed_favourites"
		group by	1
			having	count (1) <> 0
	union all
	select			"new_status_id",
				count (1)
		from		"changed_favourites"
		group by	1
			having	count (1) <> 0;
	return null;
end
$$;


--
-- Name: update_status_statistics_after_delete(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_status_statistics_after_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."status_reply_statistics" ("status_id")
	select			"in_reply_to_id"
		from		"old_data"
		where		"in_reply_to_id" is not null
		group by	1
			having	count (1) > 0;
	insert into		"queues"."status_reblog_statistics" ("status_id")
	select			"reblog_of_id"
		from		"old_data"
		where		"reblog_of_id" is not null
		group by	1
			having	count (1) > 0
	union all
	select			"quote_id"
		from		"old_data"
		where		"quote_id" is not null
		group by	1
			having	count (1) > 0;
	return null;
end
$$;


--
-- Name: update_status_statistics_after_insert(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_status_statistics_after_insert() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into		"queues"."status_reply_statistics" ("status_id")
	select			"in_reply_to_id"
		from		"new_data"
		where		"in_reply_to_id" is not null
		group by	1
			having	count (1) <> 0;
	insert into		"queues"."status_reblog_statistics" ("status_id")
	select			"reblog_of_id"
		from		"new_data"
		where		"reblog_of_id" is not null
		group by	1
			having	count (1) <> 0
	union all
	select			"quote_id"
		from		"new_data"
		where		"quote_id" is not null
		group by	1
			having	count (1) <> 0;
	return null;
end
$$;


--
-- Name: update_status_statistics_after_update(); Type: FUNCTION; Schema: queues; Owner: -
--

CREATE FUNCTION queues.update_status_statistics_after_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if "new"."in_reply_to_id" is distinct from "old"."in_reply_to_id" then
		insert into		"queues"."status_reply_statistics" ("status_id")
		select			"v"."status_id"
			from		(
						values	("old"."in_reply_to_id"),
							("new"."in_reply_to_id")
					) "v" ("status_id")
			where		"v"."status_id" is not null;
	end if;
	if (
		"new"."reblog_of_id" is distinct from "old"."reblog_of_id"
	or	"new"."quote_id" is distinct from "old"."quote_id"
	) then
		insert into		"queues"."status_reply_statistics" ("status_id")
		select			"v"."status_id"
			from		(
						values	("old"."reblog_of_id"),
							("old"."quote_id"),
							("new"."in_reply_to_id"),
							("new"."quote_id")
					) "v" ("status_id")
			where		"v"."status_id" is not null;
	end if;
	return null;
end
$$;


--
-- Name: emoji_id(text); Type: FUNCTION; Schema: reference; Owner: -
--

CREATE FUNCTION reference.emoji_id(in_emoji text) RETURNS smallint
    LANGUAGE sql STABLE
    AS $$
select			"emoji_id"
	from		"reference"."emojis"
	where		"emoji" = "in_emoji"
$$;


--
-- Name: chat_events(bigint, smallint, integer, smallint, bigint, smallint); Type: FUNCTION; Schema: sevro_api; Owner: -
--

CREATE FUNCTION sevro_api.chat_events(in_account_id bigint, in_api_version smallint, in_chat_id integer DEFAULT NULL::integer, in_upgrade_from_api_version smallint DEFAULT NULL::smallint, in_greater_than_event_id bigint DEFAULT NULL::bigint, in_page_size smallint DEFAULT 20) RETURNS SETOF common_logic.paginated_json
    LANGUAGE sql
    AS $$
	with "events_basic" (
		"event_id",
		"chat_id",
		"event_type",
		"timestamp"
	) as (
		select			"event_id",
					"chat_id",
					"event_type",
					"timestamp"
			from		"common_logic"."chat_events_basic" (
						"in_account_id",
						"in_api_version",
						"in_chat_id",
						"in_upgrade_from_api_version",
						"in_greater_than_event_id",
						"in_page_size"
					)
	),
	"results" (
		"event_id",
		"chat_id",
		"event_type",
		"timestamp",
		"payload"
	) as (
		select			"e"."event_id",
					"e"."chat_id",
					case
						when	(
								"e"."event_type" = 'message_created'
							and	"in_api_version" < 2
							and	exists (
									select			1
										from		"chat_events"."message_creations" "c"
										join		"chats"."messages" "m"
											using	("message_id")
										where		"c"."event_id" = "e"."event_id"
											and	"m"."message_type" = 'media'
								)
							)
						then	'feature_unavailable'
						else	"e"."event_type"
					end,
					"e"."timestamp",
					case "e"."event_type"
						when	'chat_created'
						then	"to_jsonb" ("mastodon_chats_logic"."chat_creation_payload" ("e"."event_id", "in_account_id"))
						when	'chat_message_expiration_changed'
						then	"to_jsonb" ("mastodon_chats_logic"."chat_message_expiration_change_payload" ("e"."event_id"))
						when	'member_invited'
						then	"to_jsonb" ("mastodon_chats_logic"."member_invitation_payload" ("e"."event_id"))
						when	'member_joined'
						then	"to_jsonb" ("mastodon_chats_logic"."member_join_payload" ("e"."event_id"))
						when	'member_left'
						then	"to_jsonb" ("mastodon_chats_logic"."member_leave_payload" ("e"."event_id"))
						when	'member_rejoined'
						then	"to_jsonb" ("mastodon_chats_logic"."member_rejoin_payload" ("e"."event_id", "in_account_id"))
						when	'subscriber_left'
						then	"to_jsonb" ("mastodon_chats_logic"."subscriber_leave_payload" ("e"."event_id"))
						when	'subscriber_rejoined'
						then	"to_jsonb" ("mastodon_chats_logic"."subscriber_rejoin_payload" ("e"."event_id"))
						when	'member_latest_read_message_changed'
						then	"to_jsonb" ("mastodon_chats_logic"."member_latest_read_message_change_payload" ("e"."event_id"))
						when	'message_created'
						then	case
								when	(
										"in_api_version" < 2
									and	exists (
											select			1
												from		"chat_events"."message_creations" "c"
												join		"chats"."messages" "m"
													using	("message_id")
												where		"c"."event_id" = "e"."event_id"
													and	"m"."message_type" = 'media'
										)
									)
								then	"jsonb_build_object" (
										'text',		'Update your app to see additional content in the chat.',
										'url',		'https://apps.apple.com/us/app/truth-social/id1586018825',
										'button_text',	'Update'
									)
								else	"to_jsonb" ("mastodon_chats_logic"."message_creation_payload" ("e"."event_id", "in_account_id"))
							end
						when	'message_edited'
						then	"to_jsonb" ("mastodon_chats_logic"."message_edit_payload" ("e"."event_id", "in_account_id"))
						when	'message_hidden'
						then	"to_jsonb" ("mastodon_chats_logic"."message_hidden_payload" ("e"."event_id"))
						when	'message_deleted'
						then	"to_jsonb" ("mastodon_chats_logic"."message_deletion_payload" ("e"."event_id"))
						when	'message_reactions_changed'
						then	"to_jsonb" ("mastodon_chats_logic"."message_reactions_change_payload" ("e"."event_id", "in_account_id"))
						when	'chat_avatar_changed'
						then	"to_jsonb" ("mastodon_chats_logic"."chat_avatar_change_payload" ("e"."event_id"))
						when	'member_avatar_changed'
						then	"to_jsonb" ("mastodon_chats_logic"."member_avatar_change_payload" ("e"."event_id"))
					end
			from		"events_basic" "e"
			order by	"e"."event_id"
			limit		"in_page_size"
	)
	select			coalesce (
					"jsonb_agg" (
						"jsonb_build_object" (
							'event_id',	"event_id"::text,
							'chat_id',	"chat_id"::text,
							'event_type',	"event_type",
							'timestamp',	"common_logic"."json_format_timestamp" ("timestamp")
						)
					||	coalesce (
							"payload",
							'{}'
						)
					),
				'[]'
				),
				max ("event_id"),
				max ("event_id") = (
					select			max ("event_id")
						from		"events_basic"
				)
		from		"results"
$$;


--
-- Name: trending_group_scores(); Type: FUNCTION; Schema: trending_groups; Owner: -
--

CREATE FUNCTION trending_groups.trending_group_scores() RETURNS SETOF trending_groups.trending_group_score
    LANGUAGE sql
    AS $$
with "current_statuses" (
	"group_id",
	"accounts"
) as (
	select			"group_id",
				count (distinct "account_id")
		from		"cache"."group_status_tags"
		where		"created_at" > current_timestamp - interval '1 day'
		group by	1
),
"previous_statuses" (
	"group_id",
	"accounts"
) as (
	select			"group_id",
				count (distinct "account_id")
		from		"cache"."group_status_tags"
		where		"created_at" > current_timestamp - interval '2 days'
			and	"created_at" < current_timestamp - interval '1 day'
		group by	1
),
"previous_members" (
	"group_id",
	"members"
) as (
	select			"group_id",
				count (1)
		from		"public"."group_memberships"
		where		"created_at" < current_timestamp - interval '1 days'
		group by	1
)
select			"g"."id",
			(
				(
					"configuration"."feature_setting_value" (
						'trending_groups',
						'current_posting_account_weight'
					)::float
				*	coalesce (
						"cs"."accounts",
						0
					)
				)
			+	(
					"configuration"."feature_setting_value" (
						'trending_groups',
						'posting_account_growth_weight'
					)::float
				*	"pow" (
						greatest (
							0,
							(
								"cs"."accounts"
							-	coalesce (
									"ps"."accounts",
									0
								)
							)
						),
						2
					)
				)
			+	(
					"configuration"."feature_setting_value" (
						'trending_groups',
						'current_membership_weight'
					)::float
				*	"s"."members_count"
				)
			+	(
					"configuration"."feature_setting_value" (
						'trending_groups',
						'membership_growth_weight'
					)::float
				*	"pow" (
						greatest (
							0,
							(
								"s"."members_count"
							-	coalesce (
									"pm"."members",
									0
								)
							)
						),
						2
					)
				)
			)
	from		"public"."groups" "g"
	join		"public"."group_stats" "s"
		on	"s"."group_id" = "g"."id"
	left join	"current_statuses" "cs"
		using	("group_id")
	left join	"previous_statuses" "ps"
		using	("group_id")
	left join	"previous_members" "pm"
		using	("group_id")
	where		"g"."deleted_at" is null
		and	"s"."members_count" <= "configuration"."feature_setting_value" (
				'trending_groups',
				'maximum_group_size'
			)::int4
	order by	2 desc
	limit		"configuration"."feature_setting_value" (
				'trending_groups',
				'maximum_trending_groups'
			)::int4
$$;


--
-- Name: exclude_status(bigint); Type: FUNCTION; Schema: trending_statuses; Owner: -
--

CREATE FUNCTION trending_statuses.exclude_status(in_status_id bigint) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
select			(
				exists (
					select			1
						from		"trending_statuses"."excluded_statuses" "x"
						where		"x"."status_id" = "s"."id"
				)
			or	exists (
					select			1
						from		"configuration"."filtered_words" "x"
						where		"s"."text" ~* ('\y'||"x"."word"||'\y')
				)
			)
	from		"public"."statuses" "s"
	where		"s"."id" = "in_status_id"
$$;


--
-- Name: recent_statuses_from_followed_accounts(); Type: FUNCTION; Schema: trending_statuses; Owner: -
--

CREATE FUNCTION trending_statuses.recent_statuses_from_followed_accounts() RETURNS TABLE(status_id bigint, account_id bigint)
    LANGUAGE sql
    AS $$
select			"s"."id",
			"s"."account_id"
	from		"public"."statuses" "s"
	where		"s"."created_at" >= (
				current_timestamp at time zone 'UTC'
			-	"configuration"."feature_setting_value" (
					'trending_statuses',
					'status_created_interval'
				)::interval
			)
		and	"s"."deleted_at" is null
		and	exists (
				select			1
					from		"statistics"."account_followers" "x"
					where		"x"."account_id" = "s"."account_id"
						and	"followers_count" >= "configuration"."feature_setting_value" (
								'trending_statuses',
								'viral_minimum_followers'
							)::int
						and	"followers_count" <= "configuration"."feature_setting_value" (
								'trending_statuses',
								'viral_maximum_followers'
							)::int
			)
		and	exists (
				select			1
					from		"statistics"."status_replies" "x"
					where		"x"."status_id" = "s"."id"
			)
		and	exists (
				select			1
					from		"statistics"."status_reblogs" "x"
					where		"x"."status_id" = "s"."id"
			)
		and	exists (
				select			1
					from		"statistics"."status_favourites" "x"
					where		"x"."status_id" = "s"."id"
			)
		and	not exists (
				select			1
					from		"trending_statuses"."excluded_statuses" "x"
					where		"x"."status_id" = "s"."id"
			)
		and	not exists (
				select			1
					from		"public"."groups" "g"
					where		"g"."id" = "s"."group_id"
						and	"g"."statuses_visibility" = 'members_only'
			)
$$;


--
-- Name: status_favourites_by_nonfollowers(bigint); Type: FUNCTION; Schema: trending_statuses; Owner: -
--

CREATE FUNCTION trending_statuses.status_favourites_by_nonfollowers(in_status_id bigint) RETURNS integer
    LANGUAGE sql STABLE
    AS $_$
select			count (*)
	from		"public"."favourites" "f"
	where		"f"."status_id" = $1
		and	not exists (
				select			1
					from		"public"."follows" "x"
					where		"x"."target_account_id" = (
								select			"account_id"
									from		"public"."statuses"
									where		"id" = $1
							)
						and	"x"."account_id" = "f"."account_id"
			)
$_$;


--
-- Name: status_reblogs_by_nonfollowers(bigint); Type: FUNCTION; Schema: trending_statuses; Owner: -
--

CREATE FUNCTION trending_statuses.status_reblogs_by_nonfollowers(in_status_id bigint) RETURNS integer
    LANGUAGE sql STABLE
    AS $_$
select			count (*)
	from		"public"."statuses" "s"
	where		"reblog_of_id" = $1
		and	not exists (
				select			1
					from		"public"."follows" "x"
					where		"x"."target_account_id" = (
								select			"account_id"
									from		"public"."statuses"
									where		"id" = $1
							)
						and	"x"."account_id" = "s"."account_id"
			)
$_$;


--
-- Name: status_replies_by_nonfollowers(bigint); Type: FUNCTION; Schema: trending_statuses; Owner: -
--

CREATE FUNCTION trending_statuses.status_replies_by_nonfollowers(in_status_id bigint) RETURNS integer
    LANGUAGE sql STABLE
    AS $_$
select			count (*)
	from		"public"."statuses" "s"
	where		"in_reply_to_id" = $1
		and	not exists (
				select			1
					from		"public"."follows" "x"
					where		"x"."target_account_id" = (
								select			"account_id"
									from		"public"."statuses"
									where		"id" = $1
							)
						and	"x"."account_id" = "s"."account_id"
			)
$_$;


--
-- Name: trending_statuses_popular(); Type: FUNCTION; Schema: trending_statuses; Owner: -
--

CREATE FUNCTION trending_statuses.trending_statuses_popular() RETURNS TABLE(status_id bigint, rank double precision)
    LANGUAGE plpgsql
    AS $$
declare
	"var_maximum_statuses_per_account"	int;
	"var_minimum_followers"			int;
	"var_status_created_interval"		interval;
	"var_status_favourite_weight"		float;
	"var_status_reblog_weight"		float;
	"var_status_reply_weight"		float;
	"var_statuses_limit"			int;
begin
	"var_maximum_statuses_per_account" := "configuration"."feature_setting_value" (
		'trending_statuses',
		'maximum_statuses_per_account'
	);
	"var_minimum_followers" := "configuration"."feature_setting_value" (
		'trending_statuses',
		'popular_minimum_followers'
	);
	"var_status_created_interval" := "configuration"."feature_setting_value" (
		'trending_statuses',
		'status_created_interval'
	);
	"var_status_favourite_weight" := "configuration"."feature_setting_value" (
		'trending_statuses',
		'status_favourite_weight'
	);
	"var_status_reblog_weight" := "configuration"."feature_setting_value" (
		'trending_statuses',
		'status_reblog_weight'
	);
	"var_status_reply_weight" := "configuration"."feature_setting_value" (
		'trending_statuses',
		'status_reply_weight'
	);
	"var_statuses_limit" := (
		"configuration"."feature_setting_value" (
			'trending_statuses',
			'maximum_trending_statuses'
		)::int
	/	2
	);
	return query (
		with "results" (
			"status_id",
			"row_number",
			"rank"
		) as (
			select			"s"."id",
						row_number () over (
							partition by	"s"."account_id"
							order by	(
										(
											"r"."replies_count"
										*	"var_status_reply_weight"
										)
									+	(
											"b"."reblogs_count"
										*	"var_status_reblog_weight"
										)
									+	(
											"f"."favourites_count"
										*	"var_status_favourite_weight"
										)
									) desc
						),
						(
							(
								"r"."replies_count"
							*	"var_status_reply_weight"
							)
						+	(
								"b"."reblogs_count"
							*	"var_status_reblog_weight"
							)
						+	(
								"f"."favourites_count"
							*	"var_status_favourite_weight"
							)
						)
				from		"public"."statuses" "s"
				join		"statistics"."status_replies" "r"
					on	"r"."status_id" = "s"."id"
				join		"statistics"."status_reblogs" "b"
					on	"b"."status_id" = "s"."id"
				join		"statistics"."status_favourites" "f"
					on	"f"."status_id" = "s"."id"
				where		"s"."created_at" >= current_timestamp - "var_status_created_interval"
					and	"s"."deleted_at" is null
					and	exists (
							select			1
								from		"statistics"."account_followers" "x"
								where		"x"."account_id" = "s"."account_id"
									and	"x"."followers_count" >= "var_minimum_followers"
						)
					and	not exists (
							select			1
								from		"trending_statuses"."trending_statuses_viral" "v"
								join		"public"."statuses" "x"
									on	"x"."id" = "v"."status_id"
								where		"x"."account_id" = "s"."account_id"
						)
					and	not exists (
							select			1
								from		"trending_statuses"."excluded_statuses" "x"
								where		"x"."status_id" = "s"."id"
						)
					and	not exists (
							select			1
								from		"public"."groups" "g"
								where		"g"."id" = "s"."group_id"
									and	"g"."statuses_visibility" = 'members_only'
						)
		)
		select			"r"."status_id",
					"r"."rank"
			from		"results" "r"
			where		"r"."row_number" <= "var_maximum_statuses_per_account"
			order by	2 desc
			limit		"var_statuses_limit"
	);
end
$$;


--
-- Name: trending_statuses_viral(); Type: FUNCTION; Schema: trending_statuses; Owner: -
--

CREATE FUNCTION trending_statuses.trending_statuses_viral() RETURNS TABLE(status_id bigint, rank double precision)
    LANGUAGE plpgsql
    AS $$
declare
	"var_maximum_statuses_per_account"	int;
	"var_status_favourite_weight"		float;
	"var_status_reblog_weight"		float;
	"var_status_reply_weight"		float;
	"var_statuses_limit"			int;
begin
	"var_maximum_statuses_per_account" := "configuration"."feature_setting_value" (
		'trending_statuses',
		'maximum_statuses_per_account'
	);
	"var_status_favourite_weight" := "configuration"."feature_setting_value" (
		'trending_statuses',
		'status_favourite_weight'
	);
	"var_status_reblog_weight" := "configuration"."feature_setting_value" (
		'trending_statuses',
		'status_reblog_weight'
	);
	"var_status_reply_weight" := "configuration"."feature_setting_value" (
		'trending_statuses',
		'status_reply_weight'
	);
	"var_statuses_limit" := (
		"configuration"."feature_setting_value" (
			'trending_statuses',
			'maximum_trending_statuses'
		)::int
	/	2
	);
	return query (
		with "results" (
			"status_id",
			"row_number",
			"rank"
		) as (
			select			"s"."status_id",
						row_number () over (
							partition by	"s"."account_id"
							order by	(
										(
											(
												"r"."replies_count"
											*	"var_status_reply_weight"
											)
										+	(
												"b"."reblogs_count"
											*	"var_status_reblog_weight"
											)
										+	(
												"f"."favourites_count"
											*	"var_status_favourite_weight"
											)
										)
									/	ln ("a"."followers_count")
									) desc
						),
						(
							(
								(
									"r"."replies_count"
								*	"var_status_reply_weight"
								)
							+	(
									"b"."reblogs_count"
								*	"var_status_reblog_weight"
								)
							+	(
									"f"."favourites_count"
								*	"var_status_favourite_weight"
								)
							)
						/	ln ("a"."followers_count")
						)
				from		"trending_statuses"."recent_statuses_from_followed_accounts" "s"
				join		"statistics"."account_followers" "a"
					using	("account_id")
				join		"trending_statuses"."replies_by_nonfollowers" "r"
					using	("status_id")
				join		"trending_statuses"."reblogs_by_nonfollowers" "b"
					using	("status_id")
				join		"trending_statuses"."favourites_by_nonfollowers" "f"
					using	("status_id")
				where		(
							"r"."replies_count" > 0
						or	"b"."reblogs_count" > 0
						or	"f"."favourites_count" > 0
						)
		)
		select			"r"."status_id",
					"r"."rank"
			from		"results" "r"
			where		"r"."row_number" <= "var_maximum_statuses_per_account"
			order by	2 desc
			limit		"var_statuses_limit"
	);
end
$$;


--
-- Name: trending_tag_scores(); Type: FUNCTION; Schema: trending_tags; Owner: -
--

CREATE FUNCTION trending_tags.trending_tag_scores() RETURNS SETOF trending_tags.trending_tag_score
    LANGUAGE sql STABLE
    AS $$
with "current" (
	"tag_id",
	"account_count"
) as (
	select			"s"."tag_id",
				count (distinct "s"."account_id")
		from		"cache"."status_tags" "s"
		join		"public"."accounts" "a"
			on	"a"."id" = "s"."account_id"
		where		"s"."created_at" >= current_timestamp - interval '1 day'
			and	"a"."created_at" <= current_timestamp - "configuration"."feature_setting_value" (
					'trending_tags',
					'minimum_account_age'
				)::interval
			and	exists (
					select			1
						from		"public"."tags" "t"
						where		"t"."id" = "s"."tag_id"
							and	"t"."trendable"
				)
			and	not exists (
					select			1
						from		"public"."accounts" "a"
						where		"a"."id" = "s"."account_id"
							and	"a"."created_at" > current_timestamp - interval '7 days'
				)
		group by	1
			having	count (distinct "s"."account_id") >= "configuration"."feature_setting_value" (
					'trending_tags',
					'minimum_accounts_per_day'
				)::int4
),
"previous" (
	"tag_id",
	"account_count"
) as (
	select			"s"."tag_id",
				count (distinct "s"."account_id")
		from		"cache"."status_tags" "s"
		join		"public"."accounts" "a"
			on	"a"."id" = "s"."account_id"
		where		"s"."created_at" >= current_timestamp - interval '2 days'
			and	"s"."created_at" < current_timestamp - interval '1 day'
			and	"a"."created_at" <= current_timestamp - "configuration"."feature_setting_value" (
					'trending_tags',
					'minimum_account_age'
				)::interval
			and	exists (
					select			1
						from		"public"."tags" "t"
						where		"t"."id" = "s"."tag_id"
							and	"t"."trendable"
				)
			and	not exists (
					select			1
						from		"public"."accounts" "a"
						where		"a"."id" = "s"."account_id"
							and	"a"."created_at" > current_timestamp - interval '7 days'
				)
		group by	1
			having	count (distinct "s"."account_id") >= "configuration"."feature_setting_value" (
					'trending_tags',
					'minimum_accounts_per_day'
				)::int4
)
select			"tag_id",
			(
				(
					coalesce ("c"."account_count", 0)
				*	"configuration"."feature_setting_value" (
						'trending_tags',
						'popularity_factor'
					)::float
				)
			+	(
					"pow" (
						greatest (
							(
								coalesce ("c"."account_count", 0)
							-	coalesce ("p"."account_count", 0)
							),
							0
						),
						2
					)
				*	"configuration"."feature_setting_value" (
						'trending_tags',
						'momentum_factor'
					)::float
				)
			)::int
	from		"current" "c"
	join		"previous" "p"
		using	("tag_id")
	order by	2 desc
	limit		"configuration"."feature_setting_value" (
				'trending_tags',
				'maximum_trending_tags'
			)::int4
$$;


--
-- Name: archive_deleted_accounts(); Type: FUNCTION; Schema: tv; Owner: -
--

CREATE FUNCTION tv.archive_deleted_accounts() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
        insert into             "tv"."deleted_accounts" (
                                        "p_profile_id"
                                )
                values          (
                                        "old"."p_profile_id"
                                );
        return "old";
end
$$;


--
-- Name: array_sort(anyarray); Type: FUNCTION; Schema: utilities; Owner: -
--

CREATE FUNCTION utilities.array_sort(in_array anyarray) RETURNS anyarray
    LANGUAGE sql IMMUTABLE
    AS $$
select			array (
				select			unnest ("in_array")
					order by	1
			)
$$;


--
-- Name: array_subtract(anyarray, anyarray); Type: FUNCTION; Schema: utilities; Owner: -
--

CREATE FUNCTION utilities.array_subtract(in_array anyarray, in_remove_elements anyarray) RETURNS anyarray
    LANGUAGE sql IMMUTABLE
    AS $$
select			coalesce (
				array_agg ("element"),
				'{}'
			)
	from		unnest ("in_array") "element"
	where		"element" <> all ("in_remove_elements")
$$;


--
-- Name: interval_pretty_print(interval); Type: FUNCTION; Schema: utilities; Owner: -
--

CREATE FUNCTION utilities.interval_pretty_print(in_interval interval) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $_$
select			string_agg ("value", ', ')
	from		(
				values (
					case 	when	extract (year from "in_interval") = 0
						then	null
						when	extract (year from "in_interval") = 1
						then	to_char ("in_interval", 'FMYYY "year"')
						when	extract (year from "in_interval") < 1000
						then	to_char ("in_interval", 'FMYYY "years"')
						else	to_char ("in_interval", 'FMY,YYY "years"')
					end
				),
				(
					case extract (month from "in_interval")
						when	0
						then	null
						when	1
						then	to_char ("in_interval", 'FMMM "month"')
						else	to_char ("in_interval", 'FMMM "months"')
					end
				),
				(
					case extract (day from "in_interval")
						when	0
						then	null
						when	1
						then	to_char ("in_interval", 'FMDD "day"')
						else	to_char ("in_interval", 'FMDD "days"')
					end
				),
				(
					case extract (hour from "in_interval")
						when	0
						then	null
						when	1
						then	to_char ("in_interval", 'FMHH24 "hour"')
						else	to_char ("in_interval", 'FMHH24 "hours"')
					end
				),
				(
					case extract (minute from "in_interval")
						when	0
						then	null
						when	1
						then	to_char ("in_interval", 'FMMI "minute"')
						else	to_char ("in_interval", 'FMMI "minutes"')
					end
				),
				(
					case	when	extract (second from "in_interval") = 0
						then	null
						when	extract (second from "in_interval") = 1
						then	to_char ("in_interval", 'FMSS "second"')
						when	(
								extract (microsecond from "in_interval")
							-	(
									floor (extract (second from "in_interval"))
								*	1000000
								)
							) = 0
						then	to_char ("in_interval", 'FMSS "seconds"')
						else	regexp_replace (
								to_char ("in_interval", 'FMSS.US'),
								'00*$',
								''
							) || ' seconds'
					end
				)
			) "values" ("value");
$_$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: events; Type: TABLE; Schema: chat_events; Owner: -
--

CREATE TABLE chat_events.events (
    event_id bigint NOT NULL,
    chat_id integer NOT NULL,
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    event_type chat_events.event_type NOT NULL
);


--
-- Name: member_leaves; Type: TABLE; Schema: chat_events; Owner: -
--

CREATE TABLE chat_events.member_leaves (
    event_id bigint NOT NULL,
    account_id bigint NOT NULL
);


--
-- Name: subscriber_leaves; Type: TABLE; Schema: chat_events; Owner: -
--

CREATE TABLE chat_events.subscriber_leaves (
    event_id bigint NOT NULL,
    account_id bigint NOT NULL
);


--
-- Name: members; Type: TABLE; Schema: chats; Owner: -
--

CREATE TABLE chats.members (
    chat_id integer NOT NULL,
    account_id bigint NOT NULL,
    accepted boolean DEFAULT false NOT NULL,
    active boolean DEFAULT true NOT NULL,
    oldest_visible_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    latest_read_message_created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    silenced boolean DEFAULT false NOT NULL
);


--
-- Name: chat_member_removals; Type: VIEW; Schema: api; Owner: -
--

CREATE VIEW api.chat_member_removals AS
 SELECT e.chat_id,
    l.account_id,
    e."timestamp" AS removed_at,
    e.event_type AS removal_type
   FROM (chat_events.events e
     JOIN chat_events.member_leaves l USING (event_id))
  WHERE ((e.event_type = 'member_left'::chat_events.event_type) AND (NOT (EXISTS ( SELECT 1
           FROM chats.members x
          WHERE ((x.chat_id = e.chat_id) AND (x.account_id = l.account_id) AND x.active)))))
UNION ALL
 SELECT e.chat_id,
    l.account_id,
    e."timestamp" AS removed_at,
    e.event_type AS removal_type
   FROM (chat_events.events e
     JOIN chat_events.subscriber_leaves l USING (event_id))
  WHERE ((e.event_type = 'subscriber_left'::chat_events.event_type) AND (NOT (EXISTS ( SELECT 1
           FROM chats.members x
          WHERE ((x.chat_id = e.chat_id) AND (x.account_id = l.account_id) AND x.active)))));


--
-- Name: chat_members; Type: VIEW; Schema: api; Owner: -
--

CREATE VIEW api.chat_members AS
 SELECT chat_id,
    account_id,
    accepted,
    active,
    silenced,
    timezone('UTC'::text, latest_read_message_created_at) AS latest_read_message_created_at,
    chats.unread_messages(chat_id, account_id) AS unread_messages_count,
    chats.other_chat_members(chat_id, account_id) AS other_member_account_ids,
    chats.latest_message_at(chat_id, account_id) AS latest_message_at,
    chats.latest_message_id(chat_id, account_id) AS latest_message_id,
    chats.latest_activity_at(chat_id, account_id) AS latest_activity_at,
    chats.other_member_blocked(chat_id, account_id) AS blocked,
    chats.other_member_username(chat_id, account_id) AS other_member_username
   FROM chats.members;


--
-- Name: VIEW chat_members; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON VIEW api.chat_members IS 'Definition of chat members - one row for each member of each chat.';


--
-- Name: COLUMN chat_members.chat_id; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON COLUMN api.chat_members.chat_id IS 'Chat that the member is a part of.  This plus the account_id uniquely identify each row.  Must be defined on creation, cannot be updated.';


--
-- Name: COLUMN chat_members.account_id; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON COLUMN api.chat_members.account_id IS 'Account of the member.  This plus the chat_id uniquely identify each row.  Must be defined on creation, cannot be updated.';


--
-- Name: COLUMN chat_members.accepted; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON COLUMN api.chat_members.accepted IS 'Whether the user has accepted the invitation to join the chat.  Defaults to true for the creator of a chat, and false for all other members.';


--
-- Name: COLUMN chat_members.active; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON COLUMN api.chat_members.active IS 'Whether the user is currently in the chat.  True by default, set to false when the member leaves the chat, and back to true to rejoin.  Can be defined on creation and updated.';


--
-- Name: COLUMN chat_members.silenced; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON COLUMN api.chat_members.silenced IS 'Whether the member has notifications for the chat silenced (disabled) or not.  False by default.  Can be defined on creation and updated.';


--
-- Name: COLUMN chat_members.latest_read_message_created_at; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON COLUMN api.chat_members.latest_read_message_created_at IS 'Creation timestamp of the latest read message.  Updated to the creation time of a message when the member sends a message to the chat.  Can be defined on creation (but generally should not so default of current timestamp is used) and updated.';


--
-- Name: COLUMN chat_members.unread_messages_count; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON COLUMN api.chat_members.unread_messages_count IS 'Number of messages in the chat which are visible to the member and have a creation timestamp newer than the latest_read_message_created_at.  Read-only.';


--
-- Name: COLUMN chat_members.other_member_account_ids; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON COLUMN api.chat_members.other_member_account_ids IS 'Array of accounts in the chat other than the one in the account_id column.  For 1-1 chats, this will contain a single element, and then it is used for the name of the chat, which is different for each chat member.  Read-only.';


--
-- Name: COLUMN chat_members.latest_message_at; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON COLUMN api.chat_members.latest_message_at IS 'Creation timestamp of the latest message in the chat which is visible to the member.  Read-only.';


--
-- Name: COLUMN chat_members.latest_message_id; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON COLUMN api.chat_members.latest_message_id IS 'Message ID of the latest message in the chat which is visible to the member.  Read-only.';


--
-- Name: COLUMN chat_members.latest_activity_at; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON COLUMN api.chat_members.latest_activity_at IS 'Creation timestamp of the latest message in the chat which is visible to the member, or the creation timestamp of the chat if no messages exist.  Read-only.';


--
-- Name: COLUMN chat_members.blocked; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON COLUMN api.chat_members.blocked IS 'Whether or not the first element of other_member_account_ids is blocked by the account_id.  Can only be true for 1-1 chats, otherwise false.  Read-only.';


--
-- Name: COLUMN chat_members.other_member_username; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON COLUMN api.chat_members.other_member_username IS 'The username of the first element of other_member_account_ids.  Can only be determined for 1-1 chats, otherwise null.  Read-only.';


--
-- Name: chats; Type: TABLE; Schema: chats; Owner: -
--

CREATE TABLE chats.chats (
    chat_id integer NOT NULL,
    owner_account_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    message_expiration interval DEFAULT '14 days'::interval NOT NULL,
    chat_type chats.chat_type DEFAULT 'direct'::chats.chat_type NOT NULL
);


--
-- Name: member_lists; Type: TABLE; Schema: chats; Owner: -
--

CREATE TABLE chats.member_lists (
    chat_id integer NOT NULL,
    members bigint[] NOT NULL
);


--
-- Name: chats; Type: VIEW; Schema: api; Owner: -
--

CREATE VIEW api.chats AS
 SELECT c.chat_id,
    c.owner_account_id,
    c.created_at,
    c.message_expiration,
    c.chat_type,
    l.members
   FROM (chats.chats c
     LEFT JOIN chats.member_lists l USING (chat_id));


--
-- Name: VIEW chats; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON VIEW api.chats IS 'Definition of chats - one row per chat.';


--
-- Name: COLUMN chats.chat_id; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON COLUMN api.chats.chat_id IS 'Unique identifier for each chat.  Read-only, assigned by database.';


--
-- Name: COLUMN chats.owner_account_id; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON COLUMN api.chats.owner_account_id IS 'Account ID of the owner (by default the creator) of the chat.  Must be defined on creation.  Currently read-only.  A member record will be created for this account.';


--
-- Name: COLUMN chats.created_at; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON COLUMN api.chats.created_at IS 'When the chat was created.  Read-only, assigned by database.';


--
-- Name: COLUMN chats.message_expiration; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON COLUMN api.chats.message_expiration IS 'Current default message expiration time for the chat.  Can be defined on creation (if not, default will be used) and can be updated.';


--
-- Name: COLUMN chats.chat_type; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON COLUMN api.chats.chat_type IS 'Type of chat of either direct or channel.';


--
-- Name: COLUMN chats.members; Type: COMMENT; Schema: api; Owner: -
--

COMMENT ON COLUMN api.chats.members IS 'Array of account IDs of all members in the chat, sorted numerically.  Used to check if a 1-1 chat already exists before creating a new one.  Can be defined upon creation.  A member record will be created for each account in this list upon creation, and records will be added/removed for each account added/removed from this list when updated.';


--
-- Name: filtered_words; Type: TABLE; Schema: configuration; Owner: -
--

CREATE TABLE configuration.filtered_words (
    id smallint NOT NULL,
    word text NOT NULL
);


--
-- Name: trending_status_excluded_regular_expressions; Type: VIEW; Schema: api; Owner: -
--

CREATE VIEW api.trending_status_excluded_regular_expressions AS
 SELECT id,
    word AS expression
   FROM configuration.filtered_words;


--
-- Name: excluded_statuses; Type: TABLE; Schema: trending_statuses; Owner: -
--

CREATE TABLE trending_statuses.excluded_statuses (
    status_id bigint NOT NULL
);


--
-- Name: trending_status_excluded_statuses; Type: VIEW; Schema: api; Owner: -
--

CREATE VIEW api.trending_status_excluded_statuses AS
 SELECT status_id
   FROM trending_statuses.excluded_statuses
  ORDER BY status_id;


--
-- Name: feature_settings; Type: TABLE; Schema: configuration; Owner: -
--

CREATE TABLE configuration.feature_settings (
    feature_id smallint NOT NULL,
    name text NOT NULL,
    value_type configuration.value_type NOT NULL,
    value text NOT NULL
);


--
-- Name: features; Type: TABLE; Schema: configuration; Owner: -
--

CREATE TABLE configuration.features (
    feature_id smallint NOT NULL,
    name text NOT NULL
);


--
-- Name: trending_status_settings; Type: VIEW; Schema: api; Owner: -
--

CREATE VIEW api.trending_status_settings AS
 SELECT s.name,
    s.value,
    s.value_type
   FROM (configuration.feature_settings s
     JOIN configuration.features f USING (feature_id))
  WHERE (f.name = 'trending_statuses'::text);


--
-- Name: statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.statuses (
    id bigint DEFAULT public.timestamp_id('statuses'::text) NOT NULL,
    uri character varying,
    text text DEFAULT ''::text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    in_reply_to_id bigint,
    reblog_of_id bigint,
    url character varying,
    sensitive boolean DEFAULT false NOT NULL,
    visibility integer DEFAULT 0 NOT NULL,
    spoiler_text text DEFAULT ''::text NOT NULL,
    reply boolean DEFAULT false NOT NULL,
    language character varying,
    conversation_id bigint,
    local boolean,
    account_id bigint NOT NULL,
    application_id bigint,
    in_reply_to_account_id bigint,
    quote_id bigint,
    deleted_at timestamp without time zone,
    deleted_by_id bigint,
    group_id bigint,
    group_timeline_visible boolean DEFAULT false,
    has_poll boolean DEFAULT false NOT NULL
)
WITH (fillfactor='80');


--
-- Name: trending_statuses_popular; Type: MATERIALIZED VIEW; Schema: trending_statuses; Owner: -
--

CREATE MATERIALIZED VIEW trending_statuses.trending_statuses_popular AS
 SELECT status_id,
    rank
   FROM trending_statuses.trending_statuses_popular() trending_statuses_popular(status_id, rank)
  WITH NO DATA;


--
-- Name: trending_statuses_viral; Type: MATERIALIZED VIEW; Schema: trending_statuses; Owner: -
--

CREATE MATERIALIZED VIEW trending_statuses.trending_statuses_viral AS
 SELECT status_id,
    rank
   FROM trending_statuses.trending_statuses_viral() trending_statuses_viral(status_id, rank)
  WITH NO DATA;


--
-- Name: trending_statuses; Type: MATERIALIZED VIEW; Schema: trending_statuses; Owner: -
--

CREATE MATERIALIZED VIEW trending_statuses.trending_statuses AS
 WITH trending_statuses_all(row_number, trending_type, status_id) AS (
         SELECT row_number() OVER (ORDER BY t.rank DESC) AS row_number,
            'popular'::text AS "?column?",
            t.status_id
           FROM trending_statuses.trending_statuses_popular t
          WHERE ((NOT (EXISTS ( SELECT 1
                   FROM public.statuses
                  WHERE ((statuses.id = t.status_id) AND (statuses.deleted_at IS NOT NULL))))) AND (NOT trending_statuses.exclude_status(t.status_id)))
        UNION ALL
         SELECT row_number() OVER (ORDER BY t.rank DESC) AS row_number,
            'viral'::text AS text,
            t.status_id
           FROM trending_statuses.trending_statuses_viral t
          WHERE ((NOT (EXISTS ( SELECT 1
                   FROM public.statuses
                  WHERE ((statuses.id = t.status_id) AND (statuses.deleted_at IS NOT NULL))))) AND (NOT trending_statuses.exclude_status(t.status_id)))
        )
 SELECT status_id,
    row_number() OVER (ORDER BY row_number, trending_type DESC) AS sort_order,
    trending_type
   FROM trending_statuses_all
  WITH NO DATA;


--
-- Name: trending_statuses; Type: VIEW; Schema: api; Owner: -
--

CREATE VIEW api.trending_statuses AS
 SELECT status_id,
    sort_order,
    trending_type
   FROM trending_statuses.trending_statuses;


--
-- Name: group_status_tags; Type: TABLE; Schema: cache; Owner: -
--

CREATE TABLE cache.group_status_tags (
    status_id bigint NOT NULL,
    tag_id bigint NOT NULL,
    group_id bigint NOT NULL,
    account_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: group_tag_uses; Type: MATERIALIZED VIEW; Schema: cache; Owner: -
--

CREATE MATERIALIZED VIEW cache.group_tag_uses AS
 SELECT group_id,
    tag_id,
    count(*) AS uses,
    count(DISTINCT account_id) AS accounts
   FROM cache.group_status_tags
  GROUP BY group_id, tag_id
  WITH NO DATA;


--
-- Name: status_tags; Type: TABLE; Schema: cache; Owner: -
--

CREATE TABLE cache.status_tags (
    status_id bigint NOT NULL,
    tag_id bigint NOT NULL,
    account_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: tag_uses; Type: MATERIALIZED VIEW; Schema: cache; Owner: -
--

CREATE MATERIALIZED VIEW cache.tag_uses AS
 SELECT tag_id,
    count(*) AS uses
   FROM cache.status_tags
  GROUP BY tag_id
  WITH NO DATA;


--
-- Name: chat_message_expiration_changes; Type: TABLE; Schema: chat_events; Owner: -
--

CREATE TABLE chat_events.chat_message_expiration_changes (
    event_id bigint NOT NULL,
    message_expiration interval NOT NULL,
    changed_by_account_id bigint
);


--
-- Name: chat_silences; Type: TABLE; Schema: chat_events; Owner: -
--

CREATE TABLE chat_events.chat_silences (
    event_id bigint NOT NULL,
    account_id bigint NOT NULL
);


--
-- Name: chat_unsilences; Type: TABLE; Schema: chat_events; Owner: -
--

CREATE TABLE chat_events.chat_unsilences (
    event_id bigint NOT NULL,
    account_id bigint NOT NULL
);


--
-- Name: events_event_id_seq; Type: SEQUENCE; Schema: chat_events; Owner: -
--

ALTER TABLE chat_events.events ALTER COLUMN event_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME chat_events.events_event_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: member_avatar_changes; Type: TABLE; Schema: chat_events; Owner: -
--

CREATE TABLE chat_events.member_avatar_changes (
    event_id bigint NOT NULL,
    account_id bigint NOT NULL
);


--
-- Name: member_invitations; Type: TABLE; Schema: chat_events; Owner: -
--

CREATE TABLE chat_events.member_invitations (
    event_id bigint NOT NULL,
    invited_account_id bigint NOT NULL,
    invited_by_account_id bigint
);


--
-- Name: member_joins; Type: TABLE; Schema: chat_events; Owner: -
--

CREATE TABLE chat_events.member_joins (
    event_id bigint NOT NULL,
    account_id bigint NOT NULL
);


--
-- Name: member_latest_read_message_changes; Type: TABLE; Schema: chat_events; Owner: -
--

CREATE TABLE chat_events.member_latest_read_message_changes (
    event_id bigint NOT NULL,
    account_id bigint NOT NULL
);


--
-- Name: member_rejoins; Type: TABLE; Schema: chat_events; Owner: -
--

CREATE TABLE chat_events.member_rejoins (
    event_id bigint NOT NULL,
    account_id bigint NOT NULL
);


--
-- Name: message_creations; Type: TABLE; Schema: chat_events; Owner: -
--

CREATE TABLE chat_events.message_creations (
    event_id bigint NOT NULL,
    message_id bigint NOT NULL
);


--
-- Name: message_deletions; Type: TABLE; Schema: chat_events; Owner: -
--

CREATE TABLE chat_events.message_deletions (
    event_id bigint NOT NULL,
    message_id bigint NOT NULL
);


--
-- Name: message_edits; Type: TABLE; Schema: chat_events; Owner: -
--

CREATE TABLE chat_events.message_edits (
    event_id bigint NOT NULL,
    message_id bigint NOT NULL
);


--
-- Name: message_hides; Type: TABLE; Schema: chat_events; Owner: -
--

CREATE TABLE chat_events.message_hides (
    event_id bigint NOT NULL,
    message_id bigint NOT NULL,
    account_id bigint NOT NULL
);


--
-- Name: message_reactions_changes; Type: TABLE; Schema: chat_events; Owner: -
--

CREATE TABLE chat_events.message_reactions_changes (
    event_id bigint NOT NULL,
    message_id bigint NOT NULL
);


--
-- Name: subscriber_rejoins; Type: TABLE; Schema: chat_events; Owner: -
--

CREATE TABLE chat_events.subscriber_rejoins (
    event_id bigint NOT NULL,
    account_id bigint NOT NULL
);


--
-- Name: chat_message_expiration_changes; Type: TABLE; Schema: chats; Owner: -
--

CREATE TABLE chats.chat_message_expiration_changes (
    chat_id integer NOT NULL,
    changed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    message_expiration interval NOT NULL,
    changed_by_account_id bigint
);


--
-- Name: chats_chat_id_seq; Type: SEQUENCE; Schema: chats; Owner: -
--

ALTER TABLE chats.chats ALTER COLUMN chat_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME chats.chats_chat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: deleted_chats; Type: TABLE; Schema: chats; Owner: -
--

CREATE TABLE chats.deleted_chats (
    deleted_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    chat_id integer NOT NULL,
    owner_account_id bigint NOT NULL,
    created_at timestamp with time zone NOT NULL,
    message_expiration interval NOT NULL,
    chat_type chats.chat_type NOT NULL
);


--
-- Name: deleted_members; Type: TABLE; Schema: chats; Owner: -
--

CREATE TABLE chats.deleted_members (
    deleted_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    chat_id integer NOT NULL,
    account_id bigint NOT NULL,
    accepted boolean NOT NULL,
    active boolean NOT NULL,
    oldest_visible_at timestamp with time zone NOT NULL,
    latest_read_message_created_at timestamp with time zone NOT NULL,
    silenced boolean NOT NULL
);


--
-- Name: deleted_message_text; Type: TABLE; Schema: chats; Owner: -
--

CREATE TABLE chats.deleted_message_text (
    deleted_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    message_id bigint NOT NULL,
    content text NOT NULL
);


--
-- Name: deleted_messages; Type: TABLE; Schema: chats; Owner: -
--

CREATE TABLE chats.deleted_messages (
    deleted_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    message_id bigint NOT NULL,
    chat_id integer NOT NULL,
    message_type chats.message_type NOT NULL,
    created_at timestamp with time zone NOT NULL,
    expiration interval NOT NULL,
    created_by_account_id bigint NOT NULL
);


--
-- Name: hidden_messages; Type: TABLE; Schema: chats; Owner: -
--

CREATE TABLE chats.hidden_messages (
    account_id bigint NOT NULL,
    message_id bigint NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: latest_message_reactions; Type: TABLE; Schema: chats; Owner: -
--

CREATE TABLE chats.latest_message_reactions (
    message_id bigint NOT NULL,
    changed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: member_lists_chat_id_seq; Type: SEQUENCE; Schema: chats; Owner: -
--

ALTER TABLE chats.member_lists ALTER COLUMN chat_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME chats.member_lists_chat_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: message_idempotency_keys; Type: TABLE; Schema: chats; Owner: -
--

CREATE TABLE chats.message_idempotency_keys (
    message_id bigint NOT NULL,
    oauth_access_token_id bigint NOT NULL,
    idempotency_key uuid NOT NULL
);


--
-- Name: message_media_attachments; Type: TABLE; Schema: chats; Owner: -
--

CREATE TABLE chats.message_media_attachments (
    message_id bigint NOT NULL,
    media_attachment_id bigint NOT NULL
);


--
-- Name: message_text; Type: TABLE; Schema: chats; Owner: -
--

CREATE TABLE chats.message_text (
    message_id bigint NOT NULL,
    content text NOT NULL
);


--
-- Name: messages; Type: TABLE; Schema: chats; Owner: -
--

CREATE TABLE chats.messages (
    message_id bigint NOT NULL,
    chat_id integer NOT NULL,
    message_type chats.message_type DEFAULT 'text'::chats.message_type NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expiration interval DEFAULT '00:00:00'::interval NOT NULL,
    created_by_account_id bigint NOT NULL
);


--
-- Name: messages_message_id_seq; Type: SEQUENCE; Schema: chats; Owner: -
--

ALTER TABLE chats.messages ALTER COLUMN message_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME chats.messages_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: reactions; Type: TABLE; Schema: chats; Owner: -
--

CREATE TABLE chats.reactions (
    message_id bigint NOT NULL,
    emoji_id smallint NOT NULL,
    account_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: subscriber_counts; Type: TABLE; Schema: chats; Owner: -
--

CREATE TABLE chats.subscriber_counts (
    chat_id integer NOT NULL,
    subscriber_count integer NOT NULL
);


--
-- Name: account_enabled_features; Type: TABLE; Schema: configuration; Owner: -
--

CREATE TABLE configuration.account_enabled_features (
    account_id bigint NOT NULL,
    feature_flag_id smallint NOT NULL
);


--
-- Name: banned_words; Type: TABLE; Schema: configuration; Owner: -
--

CREATE TABLE configuration.banned_words (
    id smallint NOT NULL,
    word text NOT NULL
);


--
-- Name: banned_words_id_seq; Type: SEQUENCE; Schema: configuration; Owner: -
--

ALTER TABLE configuration.banned_words ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME configuration.banned_words_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: elwood; Type: TABLE; Schema: configuration; Owner: -
--

CREATE TABLE configuration.elwood (
    notification_channel text NOT NULL,
    callback_sql text NOT NULL,
    sleep_after_callback interval DEFAULT '00:00:01'::interval NOT NULL,
    enabled boolean DEFAULT true
);


--
-- Name: feature_flags; Type: TABLE; Schema: configuration; Owner: -
--

CREATE TABLE configuration.feature_flags (
    feature_flag_id smallint NOT NULL,
    name text NOT NULL,
    status configuration.feature_flag_status DEFAULT 'enabled'::configuration.feature_flag_status NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: feature_flags_feature_flag_id_seq; Type: SEQUENCE; Schema: configuration; Owner: -
--

ALTER TABLE configuration.feature_flags ALTER COLUMN feature_flag_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME configuration.feature_flags_feature_flag_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: features_feature_id_seq; Type: SEQUENCE; Schema: configuration; Owner: -
--

ALTER TABLE configuration.features ALTER COLUMN feature_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME configuration.features_feature_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: filtered_words_id_seq; Type: SEQUENCE; Schema: configuration; Owner: -
--

ALTER TABLE configuration.filtered_words ALTER COLUMN id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME configuration.filtered_words_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: global; Type: TABLE; Schema: configuration; Owner: -
--

CREATE TABLE configuration.global (
    name text NOT NULL,
    value text NOT NULL
);


--
-- Name: platforms; Type: TABLE; Schema: devices; Owner: -
--

CREATE TABLE devices.platforms (
    platform_id smallint NOT NULL,
    name text NOT NULL
);


--
-- Name: verification_chat_messages; Type: TABLE; Schema: devices; Owner: -
--

CREATE TABLE devices.verification_chat_messages (
    verification_id bigint NOT NULL,
    message_id bigint NOT NULL
);


--
-- Name: verification_favourites; Type: TABLE; Schema: devices; Owner: -
--

CREATE TABLE devices.verification_favourites (
    verification_id bigint NOT NULL,
    favourite_id bigint NOT NULL
);


--
-- Name: verification_registrations; Type: TABLE; Schema: devices; Owner: -
--

CREATE TABLE devices.verification_registrations (
    verification_id bigint NOT NULL,
    registration_id bigint NOT NULL
);


--
-- Name: verification_statuses; Type: TABLE; Schema: devices; Owner: -
--

CREATE TABLE devices.verification_statuses (
    verification_id bigint NOT NULL,
    status_id bigint NOT NULL
);


--
-- Name: verification_users; Type: TABLE; Schema: devices; Owner: -
--

CREATE TABLE devices.verification_users (
    verification_id bigint NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: verifications; Type: TABLE; Schema: devices; Owner: -
--

CREATE TABLE devices.verifications (
    verification_id bigint NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP) NOT NULL,
    remote_ip inet NOT NULL,
    platform_id smallint NOT NULL,
    details jsonb NOT NULL
);


--
-- Name: verifications_verification_id_seq; Type: SEQUENCE; Schema: devices; Owner: -
--

ALTER TABLE devices.verifications ALTER COLUMN verification_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME devices.verifications_verification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: account_feeds; Type: TABLE; Schema: feeds; Owner: -
--

CREATE TABLE feeds.account_feeds (
    account_feed_id bigint NOT NULL,
    account_id bigint NOT NULL,
    feed_id bigint NOT NULL,
    pinned boolean DEFAULT false NOT NULL,
    "position" smallint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: account_feeds_account_feed_id_seq; Type: SEQUENCE; Schema: feeds; Owner: -
--

ALTER TABLE feeds.account_feeds ALTER COLUMN account_feed_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME feeds.account_feeds_account_feed_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: feed_accounts; Type: TABLE; Schema: feeds; Owner: -
--

CREATE TABLE feeds.feed_accounts (
    feed_id bigint NOT NULL,
    account_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: feeds; Type: TABLE; Schema: feeds; Owner: -
--

CREATE TABLE feeds.feeds (
    feed_id bigint NOT NULL,
    name text NOT NULL,
    description text NOT NULL,
    created_by_account_id bigint NOT NULL,
    visibility feeds.visibility_type DEFAULT 'private'::feeds.visibility_type NOT NULL,
    feed_type feeds.feed_type DEFAULT 'custom'::feeds.feed_type NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: feeds_feed_id_seq; Type: SEQUENCE; Schema: feeds; Owner: -
--

ALTER TABLE feeds.feeds ALTER COLUMN feed_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME feeds.feeds_feed_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: cities; Type: TABLE; Schema: geography; Owner: -
--

CREATE TABLE geography.cities (
    city_id integer NOT NULL,
    name text NOT NULL,
    region_id integer NOT NULL
);


--
-- Name: cities_city_id_seq; Type: SEQUENCE; Schema: geography; Owner: -
--

ALTER TABLE geography.cities ALTER COLUMN city_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME geography.cities_city_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: countries; Type: TABLE; Schema: geography; Owner: -
--

CREATE TABLE geography.countries (
    country_id smallint NOT NULL,
    code character(2) NOT NULL,
    name text NOT NULL
);


--
-- Name: countries_country_id_seq; Type: SEQUENCE; Schema: geography; Owner: -
--

ALTER TABLE geography.countries ALTER COLUMN country_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME geography.countries_country_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: regions; Type: TABLE; Schema: geography; Owner: -
--

CREATE TABLE geography.regions (
    region_id integer NOT NULL,
    code text NOT NULL,
    name text NOT NULL,
    country_id smallint NOT NULL
);


--
-- Name: regions_region_id_seq; Type: SEQUENCE; Schema: geography; Owner: -
--

ALTER TABLE geography.regions ALTER COLUMN region_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME geography.regions_region_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: account_deletions; Type: TABLE; Schema: logs; Owner: -
--

CREATE TABLE logs.account_deletions (
    account_id bigint NOT NULL,
    user_id bigint NOT NULL,
    username text NOT NULL,
    email text NOT NULL,
    deleted_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    account_deletion_type logs.account_deletion_type NOT NULL,
    deleted_by_account_id bigint
);


--
-- Name: account_followers; Type: TABLE; Schema: statistics; Owner: -
--

CREATE TABLE statistics.account_followers (
    account_id bigint NOT NULL,
    followers_count integer NOT NULL
)
WITH (fillfactor='80');


--
-- Name: account_follower_statistics; Type: VIEW; Schema: mastodon_api; Owner: -
--

CREATE VIEW mastodon_api.account_follower_statistics AS
 SELECT account_id,
    followers_count
   FROM statistics.account_followers;


--
-- Name: account_following; Type: TABLE; Schema: statistics; Owner: -
--

CREATE TABLE statistics.account_following (
    account_id bigint NOT NULL,
    following_count integer NOT NULL
)
WITH (fillfactor='80');


--
-- Name: account_following_statistics; Type: VIEW; Schema: mastodon_api; Owner: -
--

CREATE VIEW mastodon_api.account_following_statistics AS
 SELECT account_id,
    following_count
   FROM statistics.account_following;


--
-- Name: account_statuses; Type: TABLE; Schema: statistics; Owner: -
--

CREATE TABLE statistics.account_statuses (
    account_id bigint NOT NULL,
    statuses_count integer NOT NULL,
    last_status_at timestamp without time zone NOT NULL,
    last_following_status_at timestamp without time zone
)
WITH (fillfactor='80');


--
-- Name: account_status_statistics; Type: VIEW; Schema: mastodon_api; Owner: -
--

CREATE VIEW mastodon_api.account_status_statistics AS
 SELECT account_id,
    statuses_count,
    last_status_at,
    last_following_status_at
   FROM statistics.account_statuses;


--
-- Name: status_favourites; Type: TABLE; Schema: statistics; Owner: -
--

CREATE TABLE statistics.status_favourites (
    status_id bigint NOT NULL,
    favourites_count integer NOT NULL
)
WITH (fillfactor='80');


--
-- Name: status_favourite_statistics; Type: VIEW; Schema: mastodon_api; Owner: -
--

CREATE VIEW mastodon_api.status_favourite_statistics AS
 SELECT status_id,
    favourites_count
   FROM statistics.status_favourites;


--
-- Name: status_reblogs; Type: TABLE; Schema: statistics; Owner: -
--

CREATE TABLE statistics.status_reblogs (
    status_id bigint NOT NULL,
    reblogs_count integer NOT NULL,
    rebloggers_count integer DEFAULT 0 NOT NULL
)
WITH (fillfactor='80');


--
-- Name: status_reblog_statistics; Type: VIEW; Schema: mastodon_api; Owner: -
--

CREATE VIEW mastodon_api.status_reblog_statistics AS
 SELECT status_id,
    reblogs_count
   FROM statistics.status_reblogs;


--
-- Name: status_replies; Type: TABLE; Schema: statistics; Owner: -
--

CREATE TABLE statistics.status_replies (
    status_id bigint NOT NULL,
    replies_count integer NOT NULL,
    repliers_count integer NOT NULL
)
WITH (fillfactor='80');


--
-- Name: status_reply_statistics; Type: VIEW; Schema: mastodon_api; Owner: -
--

CREATE VIEW mastodon_api.status_reply_statistics AS
 SELECT status_id,
    replies_count
   FROM statistics.status_replies;


--
-- Name: trending_statuses; Type: VIEW; Schema: mastodon_api; Owner: -
--

CREATE VIEW mastodon_api.trending_statuses AS
 SELECT status_id,
    sort_order,
    trending_type
   FROM trending_statuses.trending_statuses;


--
-- Name: marketing; Type: TABLE; Schema: notifications; Owner: -
--

CREATE TABLE notifications.marketing (
    marketing_id bigint NOT NULL,
    status_id bigint NOT NULL,
    message text NOT NULL,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: marketing_analytics; Type: TABLE; Schema: notifications; Owner: -
--

CREATE TABLE notifications.marketing_analytics (
    marketing_id bigint NOT NULL,
    oauth_access_token_id bigint NOT NULL,
    opened boolean DEFAULT false NOT NULL,
    platform integer DEFAULT 0
);


--
-- Name: marketing_marketing_id_seq; Type: SEQUENCE; Schema: notifications; Owner: -
--

ALTER TABLE notifications.marketing ALTER COLUMN marketing_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME notifications.marketing_marketing_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id bigint NOT NULL,
    activity_id bigint NOT NULL,
    activity_type character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    account_id bigint NOT NULL,
    from_account_id bigint NOT NULL,
    type character varying,
    count integer
)
PARTITION BY RANGE (((((floor(date_part('julian'::text, created_at)))::integer / 7) % 6)));


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: part_1; Type: TABLE; Schema: notifications; Owner: -
--

CREATE TABLE notifications.part_1 (
    id bigint DEFAULT nextval('public.notifications_id_seq'::regclass) NOT NULL,
    activity_id bigint NOT NULL,
    activity_type character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    account_id bigint NOT NULL,
    from_account_id bigint NOT NULL,
    type character varying,
    count integer
);

ALTER TABLE ONLY notifications.part_1 REPLICA IDENTITY FULL;


--
-- Name: part_2; Type: TABLE; Schema: notifications; Owner: -
--

CREATE TABLE notifications.part_2 (
    id bigint DEFAULT nextval('public.notifications_id_seq'::regclass) NOT NULL,
    activity_id bigint NOT NULL,
    activity_type character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    account_id bigint NOT NULL,
    from_account_id bigint NOT NULL,
    type character varying,
    count integer
);

ALTER TABLE ONLY notifications.part_2 REPLICA IDENTITY FULL;


--
-- Name: part_3; Type: TABLE; Schema: notifications; Owner: -
--

CREATE TABLE notifications.part_3 (
    id bigint DEFAULT nextval('public.notifications_id_seq'::regclass) NOT NULL,
    activity_id bigint NOT NULL,
    activity_type character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    account_id bigint NOT NULL,
    from_account_id bigint NOT NULL,
    type character varying,
    count integer
);

ALTER TABLE ONLY notifications.part_3 REPLICA IDENTITY FULL;


--
-- Name: part_4; Type: TABLE; Schema: notifications; Owner: -
--

CREATE TABLE notifications.part_4 (
    id bigint DEFAULT nextval('public.notifications_id_seq'::regclass) NOT NULL,
    activity_id bigint NOT NULL,
    activity_type character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    account_id bigint NOT NULL,
    from_account_id bigint NOT NULL,
    type character varying,
    count integer
);

ALTER TABLE ONLY notifications.part_4 REPLICA IDENTITY FULL;


--
-- Name: part_5; Type: TABLE; Schema: notifications; Owner: -
--

CREATE TABLE notifications.part_5 (
    id bigint DEFAULT nextval('public.notifications_id_seq'::regclass) NOT NULL,
    activity_id bigint NOT NULL,
    activity_type character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    account_id bigint NOT NULL,
    from_account_id bigint NOT NULL,
    type character varying,
    count integer
);

ALTER TABLE ONLY notifications.part_5 REPLICA IDENTITY FULL;


--
-- Name: part_6; Type: TABLE; Schema: notifications; Owner: -
--

CREATE TABLE notifications.part_6 (
    id bigint DEFAULT nextval('public.notifications_id_seq'::regclass) NOT NULL,
    activity_id bigint NOT NULL,
    activity_type character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    account_id bigint NOT NULL,
    from_account_id bigint NOT NULL,
    type character varying,
    count integer
);

ALTER TABLE ONLY notifications.part_6 REPLICA IDENTITY FULL;


--
-- Name: integrity_credentials; Type: TABLE; Schema: oauth_access_tokens; Owner: -
--

CREATE TABLE oauth_access_tokens.integrity_credentials (
    oauth_access_token_id bigint NOT NULL,
    verification_id bigint NOT NULL,
    user_agent text NOT NULL,
    last_verified_at timestamp without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP) NOT NULL
);


--
-- Name: webauthn_credentials; Type: TABLE; Schema: oauth_access_tokens; Owner: -
--

CREATE TABLE oauth_access_tokens.webauthn_credentials (
    oauth_access_token_id bigint NOT NULL,
    webauthn_credential_id bigint NOT NULL,
    user_agent text NOT NULL,
    last_verified_at timestamp without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP) NOT NULL
);


--
-- Name: options; Type: TABLE; Schema: polls; Owner: -
--

CREATE TABLE polls.options (
    poll_id integer NOT NULL,
    option_number smallint NOT NULL,
    text text NOT NULL
);


--
-- Name: polls; Type: TABLE; Schema: polls; Owner: -
--

CREATE TABLE polls.polls (
    poll_id integer NOT NULL,
    expires_at timestamp(0) without time zone DEFAULT (CURRENT_TIMESTAMP + '2 days'::interval) NOT NULL,
    multiple_choice boolean DEFAULT false NOT NULL
);


--
-- Name: polls_poll_id_seq; Type: SEQUENCE; Schema: polls; Owner: -
--

ALTER TABLE polls.polls ALTER COLUMN poll_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME polls.polls_poll_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: status_polls; Type: TABLE; Schema: polls; Owner: -
--

CREATE TABLE polls.status_polls (
    status_id bigint NOT NULL,
    poll_id integer NOT NULL
);


--
-- Name: votes; Type: TABLE; Schema: polls; Owner: -
--

CREATE TABLE polls.votes (
    poll_id integer NOT NULL,
    option_number smallint NOT NULL,
    account_id bigint NOT NULL
);


--
-- Name: account_aliases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_aliases (
    id bigint NOT NULL,
    account_id bigint,
    acct character varying DEFAULT ''::character varying NOT NULL,
    uri character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: account_aliases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_aliases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_aliases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_aliases_id_seq OWNED BY public.account_aliases.id;


--
-- Name: account_conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_conversations (
    id bigint NOT NULL,
    account_id bigint,
    conversation_id bigint,
    participant_account_ids bigint[] DEFAULT '{}'::bigint[] NOT NULL,
    status_ids bigint[] DEFAULT '{}'::bigint[] NOT NULL,
    last_status_id bigint,
    lock_version integer DEFAULT 0 NOT NULL,
    unread boolean DEFAULT false NOT NULL
);


--
-- Name: account_conversations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_conversations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_conversations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_conversations_id_seq OWNED BY public.account_conversations.id;


--
-- Name: account_deletion_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_deletion_requests (
    id bigint NOT NULL,
    account_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: account_deletion_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_deletion_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_deletion_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_deletion_requests_id_seq OWNED BY public.account_deletion_requests.id;


--
-- Name: account_domain_blocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_domain_blocks (
    domain character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    account_id bigint,
    id bigint NOT NULL
);


--
-- Name: account_domain_blocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_domain_blocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_domain_blocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_domain_blocks_id_seq OWNED BY public.account_domain_blocks.id;


--
-- Name: account_identity_proofs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_identity_proofs (
    id bigint NOT NULL,
    account_id bigint,
    provider character varying DEFAULT ''::character varying NOT NULL,
    provider_username character varying DEFAULT ''::character varying NOT NULL,
    token text DEFAULT ''::text NOT NULL,
    verified boolean DEFAULT false NOT NULL,
    live boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: account_identity_proofs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_identity_proofs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_identity_proofs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_identity_proofs_id_seq OWNED BY public.account_identity_proofs.id;


--
-- Name: account_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_migrations (
    id bigint NOT NULL,
    account_id bigint,
    acct character varying DEFAULT ''::character varying NOT NULL,
    followers_count bigint DEFAULT 0 NOT NULL,
    target_account_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: account_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_migrations_id_seq OWNED BY public.account_migrations.id;


--
-- Name: account_moderation_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_moderation_notes (
    id bigint NOT NULL,
    content text NOT NULL,
    account_id bigint NOT NULL,
    target_account_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: account_moderation_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_moderation_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_moderation_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_moderation_notes_id_seq OWNED BY public.account_moderation_notes.id;


--
-- Name: account_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_notes (
    id bigint NOT NULL,
    account_id bigint,
    target_account_id bigint,
    comment text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: account_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_notes_id_seq OWNED BY public.account_notes.id;


--
-- Name: account_pins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_pins (
    id bigint NOT NULL,
    account_id bigint,
    target_account_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: account_pins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_pins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_pins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_pins_id_seq OWNED BY public.account_pins.id;


--
-- Name: account_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_stats (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    statuses_count bigint DEFAULT 0 NOT NULL,
    following_count bigint DEFAULT 0 NOT NULL,
    followers_count bigint DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    last_status_at timestamp without time zone
)
WITH (fillfactor='80');


--
-- Name: account_stats_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_stats_id_seq OWNED BY public.account_stats.id;


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    username character varying DEFAULT ''::character varying NOT NULL,
    domain character varying,
    private_key text,
    public_key text DEFAULT ''::text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    note text DEFAULT ''::text NOT NULL,
    display_name character varying DEFAULT ''::character varying NOT NULL,
    uri character varying DEFAULT ''::character varying NOT NULL,
    url character varying,
    avatar_file_name character varying,
    avatar_content_type character varying,
    avatar_file_size integer,
    avatar_updated_at timestamp without time zone,
    header_file_name character varying,
    header_content_type character varying,
    header_file_size integer,
    header_updated_at timestamp without time zone,
    avatar_remote_url character varying,
    locked boolean DEFAULT false NOT NULL,
    header_remote_url character varying DEFAULT ''::character varying NOT NULL,
    last_webfingered_at timestamp without time zone,
    inbox_url character varying DEFAULT ''::character varying NOT NULL,
    outbox_url character varying DEFAULT ''::character varying NOT NULL,
    shared_inbox_url character varying DEFAULT ''::character varying NOT NULL,
    followers_url character varying DEFAULT ''::character varying NOT NULL,
    protocol integer DEFAULT 0 NOT NULL,
    id bigint DEFAULT public.timestamp_id('accounts'::text) NOT NULL,
    memorial boolean DEFAULT false NOT NULL,
    moved_to_account_id bigint,
    featured_collection_url character varying,
    fields jsonb,
    actor_type character varying,
    discoverable boolean,
    also_known_as character varying[],
    silenced_at timestamp without time zone,
    suspended_at timestamp without time zone,
    trust_level integer,
    hide_collections boolean,
    avatar_storage_schema_version integer,
    header_storage_schema_version integer,
    devices_url character varying,
    sensitized_at timestamp without time zone,
    suspension_origin integer,
    settings_store jsonb DEFAULT '{}'::jsonb,
    verified boolean DEFAULT false NOT NULL,
    location text DEFAULT ''::text NOT NULL,
    website text DEFAULT ''::text NOT NULL,
    whale boolean DEFAULT false,
    interactions_score integer,
    file_s3_host character varying(64),
    accepting_messages boolean DEFAULT true NOT NULL,
    chats_onboarded boolean DEFAULT false NOT NULL,
    feeds_onboarded boolean DEFAULT false NOT NULL,
    show_nonmember_group_statuses boolean DEFAULT true NOT NULL,
    tv_onboarded boolean DEFAULT false NOT NULL,
    receive_only_follow_mentions boolean DEFAULT false NOT NULL
);


--
-- Name: account_summaries; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.account_summaries AS
 SELECT accounts.id AS account_id,
    mode() WITHIN GROUP (ORDER BY t0.language) AS language,
    mode() WITHIN GROUP (ORDER BY t0.sensitive) AS sensitive
   FROM (public.accounts
     CROSS JOIN LATERAL ( SELECT statuses.account_id,
            statuses.language,
            statuses.sensitive
           FROM public.statuses
          WHERE ((statuses.account_id = accounts.id) AND (statuses.deleted_at IS NULL))
          ORDER BY statuses.id DESC
         LIMIT 20) t0)
  WHERE ((accounts.suspended_at IS NULL) AND (accounts.silenced_at IS NULL) AND (accounts.moved_to_account_id IS NULL) AND (accounts.discoverable = true) AND (accounts.locked = false))
  GROUP BY accounts.id
  WITH NO DATA;


--
-- Name: account_warning_presets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_warning_presets (
    id bigint NOT NULL,
    text text DEFAULT ''::text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    title character varying DEFAULT ''::character varying NOT NULL
);


--
-- Name: account_warning_presets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_warning_presets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_warning_presets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_warning_presets_id_seq OWNED BY public.account_warning_presets.id;


--
-- Name: account_warnings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.account_warnings (
    id bigint NOT NULL,
    account_id bigint,
    target_account_id bigint,
    action integer DEFAULT 0 NOT NULL,
    text text DEFAULT ''::text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: account_warnings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.account_warnings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: account_warnings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.account_warnings_id_seq OWNED BY public.account_warnings.id;


--
-- Name: accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.accounts_id_seq OWNED BY public.accounts.id;


--
-- Name: accounts_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts_tags (
    account_id bigint NOT NULL,
    tag_id bigint NOT NULL
);


--
-- Name: ad_attributions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ad_attributions (
    ad_attribution_id bigint NOT NULL,
    payload jsonb NOT NULL,
    valid_signature boolean NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: ad_attributions_ad_attribution_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.ad_attributions ALTER COLUMN ad_attribution_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.ad_attributions_ad_attribution_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: admin_action_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_action_logs (
    id bigint NOT NULL,
    account_id bigint,
    action character varying DEFAULT ''::character varying NOT NULL,
    target_type character varying,
    target_id bigint,
    recorded_changes text DEFAULT ''::text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: admin_action_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_action_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_action_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_action_logs_id_seq OWNED BY public.admin_action_logs.id;


--
-- Name: ads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ads (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    organic_impression_url text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    status_id bigint NOT NULL
);


--
-- Name: announcement_mutes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.announcement_mutes (
    id bigint NOT NULL,
    account_id bigint,
    announcement_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: announcement_mutes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.announcement_mutes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: announcement_mutes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.announcement_mutes_id_seq OWNED BY public.announcement_mutes.id;


--
-- Name: announcement_reactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.announcement_reactions (
    id bigint NOT NULL,
    account_id bigint,
    announcement_id bigint,
    name character varying DEFAULT ''::character varying NOT NULL,
    custom_emoji_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: announcement_reactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.announcement_reactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: announcement_reactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.announcement_reactions_id_seq OWNED BY public.announcement_reactions.id;


--
-- Name: announcements; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.announcements (
    id bigint NOT NULL,
    text text DEFAULT ''::text NOT NULL,
    published boolean DEFAULT false NOT NULL,
    all_day boolean DEFAULT false NOT NULL,
    scheduled_at timestamp without time zone,
    starts_at timestamp without time zone,
    ends_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    published_at timestamp without time zone,
    status_ids bigint[]
);


--
-- Name: announcements_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.announcements_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: announcements_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.announcements_id_seq OWNED BY public.announcements.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: backups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.backups (
    id bigint NOT NULL,
    user_id bigint,
    dump_file_name character varying,
    dump_content_type character varying,
    dump_updated_at timestamp without time zone,
    processed boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    dump_file_size bigint
);


--
-- Name: backups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.backups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: backups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.backups_id_seq OWNED BY public.backups.id;


--
-- Name: blocked_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blocked_links (
    url_pattern text NOT NULL,
    status public.link_status DEFAULT 'warning'::public.link_status NOT NULL
);


--
-- Name: blocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.blocks (
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    account_id bigint NOT NULL,
    id bigint NOT NULL,
    target_account_id bigint NOT NULL,
    uri character varying
);


--
-- Name: blocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.blocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.blocks_id_seq OWNED BY public.blocks.id;


--
-- Name: bookmarks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bookmarks (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    status_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: bookmarks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bookmarks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bookmarks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bookmarks_id_seq OWNED BY public.bookmarks.id;


--
-- Name: canonical_email_blocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.canonical_email_blocks (
    id bigint NOT NULL,
    canonical_email_hash character varying DEFAULT ''::character varying NOT NULL,
    reference_account_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: canonical_email_blocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.canonical_email_blocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: canonical_email_blocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.canonical_email_blocks_id_seq OWNED BY public.canonical_email_blocks.id;


--
-- Name: conversation_mutes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversation_mutes (
    conversation_id bigint NOT NULL,
    account_id bigint NOT NULL,
    id bigint NOT NULL
);


--
-- Name: conversation_mutes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversation_mutes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversation_mutes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversation_mutes_id_seq OWNED BY public.conversation_mutes.id;


--
-- Name: conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversations (
    id bigint NOT NULL,
    uri character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: conversations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conversations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conversations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conversations_id_seq OWNED BY public.conversations.id;


--
-- Name: csv_exports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.csv_exports (
    id bigint NOT NULL,
    model character varying NOT NULL,
    app_id character varying NOT NULL,
    file_url character varying NOT NULL,
    status character varying DEFAULT 'PROCESSING'::character varying,
    user_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: csv_exports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.csv_exports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: csv_exports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.csv_exports_id_seq OWNED BY public.csv_exports.id;


--
-- Name: custom_emoji_categories; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_emoji_categories (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: custom_emoji_categories_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.custom_emoji_categories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_emoji_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.custom_emoji_categories_id_seq OWNED BY public.custom_emoji_categories.id;


--
-- Name: custom_emojis; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_emojis (
    id bigint NOT NULL,
    shortcode character varying DEFAULT ''::character varying NOT NULL,
    domain character varying,
    image_file_name character varying,
    image_content_type character varying,
    image_file_size integer,
    image_updated_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean DEFAULT false NOT NULL,
    uri character varying,
    image_remote_url character varying,
    visible_in_picker boolean DEFAULT true NOT NULL,
    category_id bigint,
    image_storage_schema_version integer
);


--
-- Name: custom_emojis_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.custom_emojis_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_emojis_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.custom_emojis_id_seq OWNED BY public.custom_emojis.id;


--
-- Name: custom_filters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_filters (
    id bigint NOT NULL,
    account_id bigint,
    expires_at timestamp without time zone,
    phrase text DEFAULT ''::text NOT NULL,
    context character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    irreversible boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    whole_word boolean DEFAULT true NOT NULL
);


--
-- Name: custom_filters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.custom_filters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_filters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.custom_filters_id_seq OWNED BY public.custom_filters.id;


--
-- Name: devices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.devices (
    id bigint NOT NULL,
    access_token_id bigint,
    account_id bigint,
    device_id character varying DEFAULT ''::character varying NOT NULL,
    name character varying DEFAULT ''::character varying NOT NULL,
    fingerprint_key text DEFAULT ''::text NOT NULL,
    identity_key text DEFAULT ''::text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: devices_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.devices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: devices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.devices_id_seq OWNED BY public.devices.id;


--
-- Name: domain_allows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.domain_allows (
    id bigint NOT NULL,
    domain character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: domain_allows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.domain_allows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: domain_allows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.domain_allows_id_seq OWNED BY public.domain_allows.id;


--
-- Name: domain_blocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.domain_blocks (
    domain character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    severity integer DEFAULT 0,
    reject_media boolean DEFAULT false NOT NULL,
    id bigint NOT NULL,
    reject_reports boolean DEFAULT false NOT NULL,
    private_comment text,
    public_comment text,
    obfuscate boolean DEFAULT false NOT NULL
);


--
-- Name: domain_blocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.domain_blocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: domain_blocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.domain_blocks_id_seq OWNED BY public.domain_blocks.id;


--
-- Name: email_domain_blocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_domain_blocks (
    id bigint NOT NULL,
    domain character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    parent_id bigint,
    disposable boolean
);


--
-- Name: email_domain_blocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.email_domain_blocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_domain_blocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.email_domain_blocks_id_seq OWNED BY public.email_domain_blocks.id;


--
-- Name: encrypted_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.encrypted_messages (
    id bigint DEFAULT public.timestamp_id('encrypted_messages'::text) NOT NULL,
    device_id bigint,
    from_account_id bigint,
    from_device_id character varying DEFAULT ''::character varying NOT NULL,
    type integer DEFAULT 0 NOT NULL,
    body text DEFAULT ''::text NOT NULL,
    digest text DEFAULT ''::text NOT NULL,
    message_franking text DEFAULT ''::text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: encrypted_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.encrypted_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: encrypted_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.encrypted_messages_id_seq OWNED BY public.encrypted_messages.id;


--
-- Name: external_ads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.external_ads (
    external_ad_id integer NOT NULL,
    ad_url text NOT NULL,
    media_url text NOT NULL,
    description text
);


--
-- Name: external_ads_external_ad_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.external_ads ALTER COLUMN external_ad_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME public.external_ads_external_ad_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: favourites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.favourites (
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    account_id bigint NOT NULL,
    id bigint NOT NULL,
    status_id bigint NOT NULL
);


--
-- Name: favourites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.favourites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: favourites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.favourites_id_seq OWNED BY public.favourites.id;


--
-- Name: featured_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.featured_tags (
    id bigint NOT NULL,
    account_id bigint,
    tag_id bigint,
    statuses_count bigint DEFAULT 0 NOT NULL,
    last_status_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: featured_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.featured_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: featured_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.featured_tags_id_seq OWNED BY public.featured_tags.id;


--
-- Name: follow_deletes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.follow_deletes (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    account_id bigint NOT NULL,
    target_account_id bigint NOT NULL
);


--
-- Name: follow_deletes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.follow_deletes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: follow_deletes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.follow_deletes_id_seq OWNED BY public.follow_deletes.id;


--
-- Name: follow_recommendation_suppressions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.follow_recommendation_suppressions (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: follow_recommendation_suppressions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.follow_recommendation_suppressions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: follow_recommendation_suppressions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.follow_recommendation_suppressions_id_seq OWNED BY public.follow_recommendation_suppressions.id;


--
-- Name: follows; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.follows (
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    account_id bigint NOT NULL,
    id bigint NOT NULL,
    target_account_id bigint NOT NULL,
    show_reblogs boolean DEFAULT true NOT NULL,
    uri character varying,
    notify boolean DEFAULT false NOT NULL
)
WITH (fillfactor='80');


--
-- Name: status_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.status_stats (
    id bigint NOT NULL,
    status_id bigint NOT NULL,
    replies_count bigint DEFAULT 0 NOT NULL,
    reblogs_count bigint DEFAULT 0 NOT NULL,
    favourites_count bigint DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
)
WITH (fillfactor='80');


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    email character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    admin boolean DEFAULT false NOT NULL,
    confirmation_token character varying,
    confirmed_at timestamp without time zone,
    confirmation_sent_at timestamp without time zone,
    unconfirmed_email character varying,
    locale character varying,
    encrypted_otp_secret character varying,
    encrypted_otp_secret_iv character varying,
    encrypted_otp_secret_salt character varying,
    consumed_timestep integer,
    otp_required_for_login boolean DEFAULT false NOT NULL,
    last_emailed_at timestamp without time zone,
    otp_backup_codes character varying[],
    filtered_languages character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    account_id bigint NOT NULL,
    id bigint NOT NULL,
    disabled boolean DEFAULT false NOT NULL,
    moderator boolean DEFAULT false NOT NULL,
    invite_id bigint,
    remember_token character varying,
    chosen_languages character varying[],
    created_by_application_id bigint,
    approved boolean DEFAULT true NOT NULL,
    sign_in_token character varying,
    sign_in_token_sent_at timestamp without time zone,
    webauthn_id character varying,
    sign_up_ip inet,
    sms character varying,
    waitlist_position integer,
    unsubscribe_from_emails boolean DEFAULT false,
    ready_to_approve integer DEFAULT 0,
    unauth_visibility boolean DEFAULT true NOT NULL,
    policy_id bigint,
    sign_up_city_id integer DEFAULT geography.city_id('Unknown'::text, '??'::text, '??'::text) NOT NULL,
    sign_up_country_id integer DEFAULT geography.country_id('??'::text) NOT NULL
);


--
-- Name: follow_recommendations; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.follow_recommendations AS
 SELECT account_id,
    sum(rank) AS rank,
    array_agg(reason) AS reason
   FROM ( SELECT account_summaries.account_id,
            ((count(follows.id))::numeric / (1.0 + (count(follows.id))::numeric)) AS rank,
            'most_followed'::text AS reason
           FROM (((public.follows
             JOIN public.account_summaries ON ((account_summaries.account_id = follows.target_account_id)))
             JOIN public.users ON ((users.account_id = follows.account_id)))
             LEFT JOIN public.follow_recommendation_suppressions ON ((follow_recommendation_suppressions.account_id = follows.target_account_id)))
          WHERE ((users.current_sign_in_at >= (now() - '30 days'::interval)) AND (account_summaries.sensitive = false) AND (follow_recommendation_suppressions.id IS NULL))
          GROUP BY account_summaries.account_id
         HAVING (count(follows.id) >= 5)
        UNION ALL
         SELECT account_summaries.account_id,
            (sum((status_stats.reblogs_count + status_stats.favourites_count)) / (1.0 + sum((status_stats.reblogs_count + status_stats.favourites_count)))) AS rank,
            'most_interactions'::text AS reason
           FROM (((public.status_stats
             JOIN public.statuses ON ((statuses.id = status_stats.status_id)))
             JOIN public.account_summaries ON ((account_summaries.account_id = statuses.account_id)))
             LEFT JOIN public.follow_recommendation_suppressions ON ((follow_recommendation_suppressions.account_id = statuses.account_id)))
          WHERE ((statuses.id >= (((date_part('epoch'::text, (now() - '30 days'::interval)) * (1000)::double precision))::bigint << 16)) AND (account_summaries.sensitive = false) AND (follow_recommendation_suppressions.id IS NULL))
          GROUP BY account_summaries.account_id
         HAVING (sum((status_stats.reblogs_count + status_stats.favourites_count)) >= (5)::numeric)) t0
  GROUP BY account_id
  ORDER BY (sum(rank)) DESC
  WITH NO DATA;


--
-- Name: follow_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.follow_requests (
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    account_id bigint NOT NULL,
    id bigint NOT NULL,
    target_account_id bigint NOT NULL,
    show_reblogs boolean DEFAULT true NOT NULL,
    uri character varying,
    notify boolean DEFAULT false NOT NULL
);


--
-- Name: follow_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.follow_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: follow_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.follow_requests_id_seq OWNED BY public.follow_requests.id;


--
-- Name: follows_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.follows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: follows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.follows_id_seq OWNED BY public.follows.id;


--
-- Name: group_account_blocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_account_blocks (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    group_id bigint NOT NULL,
    created_at timestamp(0) without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP) NOT NULL
);


--
-- Name: group_account_blocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.group_account_blocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: group_account_blocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.group_account_blocks_id_seq OWNED BY public.group_account_blocks.id;


--
-- Name: group_deletion_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_deletion_requests (
    id bigint NOT NULL,
    group_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: group_deletion_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.group_deletion_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: group_deletion_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.group_deletion_requests_id_seq OWNED BY public.group_deletion_requests.id;


--
-- Name: group_membership_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_membership_requests (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    group_id bigint NOT NULL,
    created_at timestamp(0) without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP) NOT NULL
);


--
-- Name: group_membership_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.group_membership_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: group_membership_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.group_membership_requests_id_seq OWNED BY public.group_membership_requests.id;


--
-- Name: group_memberships; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_memberships (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    group_id bigint NOT NULL,
    role public.group_membership_role DEFAULT 'user'::public.group_membership_role NOT NULL,
    created_at timestamp(0) without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP) NOT NULL,
    notify boolean DEFAULT false NOT NULL
);


--
-- Name: group_memberships_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.group_memberships_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: group_memberships_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.group_memberships_id_seq OWNED BY public.group_memberships.id;


--
-- Name: group_mutes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_mutes (
    account_id bigint NOT NULL,
    group_id bigint NOT NULL
);


--
-- Name: group_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_stats (
    id bigint NOT NULL,
    group_id bigint NOT NULL,
    statuses_count bigint DEFAULT 0 NOT NULL,
    members_count bigint DEFAULT 0 NOT NULL,
    last_status_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: group_stats_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.group_stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: group_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.group_stats_id_seq OWNED BY public.group_stats.id;


--
-- Name: group_suggestion_deletes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_suggestion_deletes (
    account_id bigint NOT NULL,
    group_id bigint NOT NULL
);


--
-- Name: group_suggestions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_suggestions (
    id bigint NOT NULL,
    group_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL
);


--
-- Name: group_suggestions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.group_suggestions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: group_suggestions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.group_suggestions_id_seq OWNED BY public.group_suggestions.id;


--
-- Name: group_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.group_tags (
    group_id bigint NOT NULL,
    tag_id bigint NOT NULL,
    group_tag_type public.group_tag_type DEFAULT 'pinned'::public.group_tag_type NOT NULL,
    CONSTRAINT group_tags_group_tag_type_check CHECK ((group_tag_type <> 'normal'::public.group_tag_type))
);


--
-- Name: groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.groups (
    id bigint DEFAULT public.timestamp_id('groups'::text) NOT NULL,
    note text NOT NULL,
    display_name text NOT NULL,
    locked boolean DEFAULT false NOT NULL,
    hide_members boolean DEFAULT false NOT NULL,
    discoverable boolean DEFAULT true NOT NULL,
    avatar_file_name text,
    avatar_content_type public.image_content_type,
    avatar_file_size integer,
    avatar_updated_at timestamp(0) without time zone,
    avatar_remote_url text,
    header_file_name text,
    header_content_type public.image_content_type,
    header_file_size integer,
    header_updated_at timestamp(0) without time zone,
    header_remote_url text,
    created_at timestamp(0) without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP) NOT NULL,
    updated_at timestamp(0) without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP) NOT NULL,
    statuses_visibility public.group_statuses_visibility DEFAULT 'everyone'::public.group_statuses_visibility NOT NULL,
    deleted_at timestamp(0) without time zone,
    slug text NOT NULL,
    owner_account_id bigint NOT NULL,
    unauth_visibility boolean DEFAULT false NOT NULL,
    sponsored boolean DEFAULT false NOT NULL
);


--
-- Name: groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.groups_id_seq OWNED BY public.groups.id;


--
-- Name: identities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.identities (
    provider character varying DEFAULT ''::character varying NOT NULL,
    uid character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    id bigint NOT NULL,
    user_id bigint
);


--
-- Name: identities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.identities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: identities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.identities_id_seq OWNED BY public.identities.id;


--
-- Name: imports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.imports (
    type integer NOT NULL,
    approved boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    data_file_name character varying,
    data_content_type character varying,
    data_file_size integer,
    data_updated_at timestamp without time zone,
    account_id bigint NOT NULL,
    id bigint NOT NULL,
    overwrite boolean DEFAULT false NOT NULL
);


--
-- Name: imports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.imports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: imports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.imports_id_seq OWNED BY public.imports.id;


--
-- Name: instances; Type: MATERIALIZED VIEW; Schema: public; Owner: -
--

CREATE MATERIALIZED VIEW public.instances AS
 WITH domain_counts(domain, accounts_count) AS (
         SELECT accounts.domain,
            count(*) AS accounts_count
           FROM public.accounts
          WHERE (accounts.domain IS NOT NULL)
          GROUP BY accounts.domain
        )
 SELECT domain_counts.domain,
    domain_counts.accounts_count
   FROM domain_counts
UNION
 SELECT domain_blocks.domain,
    COALESCE(domain_counts.accounts_count, (0)::bigint) AS accounts_count
   FROM (public.domain_blocks
     LEFT JOIN domain_counts ON (((domain_counts.domain)::text = (domain_blocks.domain)::text)))
UNION
 SELECT domain_allows.domain,
    COALESCE(domain_counts.accounts_count, (0)::bigint) AS accounts_count
   FROM (public.domain_allows
     LEFT JOIN domain_counts ON (((domain_counts.domain)::text = (domain_allows.domain)::text)))
  WITH NO DATA;


--
-- Name: invites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.invites (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    code character varying DEFAULT ''::character varying NOT NULL,
    expires_at timestamp without time zone,
    max_uses integer,
    uses integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    autofollow boolean DEFAULT false NOT NULL,
    comment text,
    email character varying
);


--
-- Name: invites_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.invites_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: invites_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.invites_id_seq OWNED BY public.invites.id;


--
-- Name: ip_blocks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ip_blocks (
    id bigint NOT NULL,
    ip inet DEFAULT '0.0.0.0'::inet NOT NULL,
    severity integer DEFAULT 0 NOT NULL,
    expires_at timestamp without time zone,
    comment text DEFAULT ''::text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: ip_blocks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ip_blocks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ip_blocks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ip_blocks_id_seq OWNED BY public.ip_blocks.id;


--
-- Name: links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.links (
    id bigint DEFAULT public.timestamp_id('links'::text) NOT NULL,
    url text NOT NULL,
    end_url text NOT NULL,
    status public.link_status DEFAULT 'normal'::public.link_status NOT NULL,
    last_visited_at timestamp without time zone,
    redirects_count smallint DEFAULT 0 NOT NULL
);


--
-- Name: links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.links_id_seq OWNED BY public.links.id;


--
-- Name: links_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.links_statuses (
    status_id bigint NOT NULL,
    link_id bigint NOT NULL
);


--
-- Name: list_accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.list_accounts (
    id bigint NOT NULL,
    list_id bigint NOT NULL,
    account_id bigint NOT NULL,
    follow_id bigint
);


--
-- Name: list_accounts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.list_accounts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: list_accounts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.list_accounts_id_seq OWNED BY public.list_accounts.id;


--
-- Name: lists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lists (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    title character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    replies_policy integer DEFAULT 0 NOT NULL
);


--
-- Name: lists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.lists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.lists_id_seq OWNED BY public.lists.id;


--
-- Name: logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.logs (
    id bigint NOT NULL,
    event character varying NOT NULL,
    message text DEFAULT ''::text NOT NULL,
    app_id character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.logs_id_seq OWNED BY public.logs.id;


--
-- Name: markers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.markers (
    id bigint NOT NULL,
    user_id bigint,
    timeline character varying DEFAULT ''::character varying NOT NULL,
    last_read_id bigint DEFAULT 0 NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: markers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.markers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: markers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.markers_id_seq OWNED BY public.markers.id;


--
-- Name: media_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.media_attachments (
    status_id bigint,
    file_file_name character varying,
    file_content_type character varying,
    file_file_size integer,
    file_updated_at timestamp without time zone,
    remote_url character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    shortcode character varying,
    type integer DEFAULT 0 NOT NULL,
    file_meta json,
    account_id bigint,
    id bigint DEFAULT public.timestamp_id('media_attachments'::text) NOT NULL,
    description text,
    scheduled_status_id bigint,
    blurhash character varying,
    processing integer,
    file_storage_schema_version integer,
    thumbnail_file_name character varying,
    thumbnail_content_type character varying,
    thumbnail_file_size integer,
    thumbnail_updated_at timestamp without time zone,
    thumbnail_remote_url character varying,
    external_video_id character varying,
    file_s3_host character varying(64)
);


--
-- Name: media_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.media_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: media_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.media_attachments_id_seq OWNED BY public.media_attachments.id;


--
-- Name: mentions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mentions (
    status_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    account_id bigint,
    id bigint NOT NULL,
    silent boolean DEFAULT false NOT NULL
);


--
-- Name: mentions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mentions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mentions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mentions_id_seq OWNED BY public.mentions.id;


--
-- Name: moderation_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.moderation_records (
    id bigint NOT NULL,
    status_id bigint,
    media_attachment_id bigint,
    analysis jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: moderation_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.moderation_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: moderation_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.moderation_records_id_seq OWNED BY public.moderation_records.id;


--
-- Name: mutes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mutes (
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    hide_notifications boolean DEFAULT true NOT NULL,
    account_id bigint NOT NULL,
    id bigint NOT NULL,
    target_account_id bigint NOT NULL,
    expires_at timestamp without time zone
);


--
-- Name: mutes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mutes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mutes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mutes_id_seq OWNED BY public.mutes.id;


--
-- Name: oauth_access_grants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_access_grants (
    token character varying NOT NULL,
    expires_in integer NOT NULL,
    redirect_uri text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    revoked_at timestamp without time zone,
    scopes character varying,
    application_id bigint NOT NULL,
    id bigint NOT NULL,
    resource_owner_id bigint NOT NULL
);


--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_access_grants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_access_grants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_access_grants_id_seq OWNED BY public.oauth_access_grants.id;


--
-- Name: oauth_access_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_access_tokens (
    token character varying NOT NULL,
    refresh_token character varying,
    expires_in integer,
    revoked_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    scopes character varying,
    application_id bigint,
    id bigint NOT NULL,
    resource_owner_id bigint
);


--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_access_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_access_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_access_tokens_id_seq OWNED BY public.oauth_access_tokens.id;


--
-- Name: oauth_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.oauth_applications (
    name character varying NOT NULL,
    uid character varying NOT NULL,
    secret character varying NOT NULL,
    redirect_uri text NOT NULL,
    scopes character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    superapp boolean DEFAULT false NOT NULL,
    website character varying,
    owner_type character varying,
    id bigint NOT NULL,
    owner_id bigint,
    confidential boolean DEFAULT true NOT NULL
);


--
-- Name: oauth_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.oauth_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: oauth_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.oauth_applications_id_seq OWNED BY public.oauth_applications.id;


--
-- Name: one_time_challenges; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.one_time_challenges (
    id bigint NOT NULL,
    challenge text NOT NULL,
    user_id bigint,
    webauthn_credential_id bigint,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    object_type public.challenge_type
);


--
-- Name: one_time_challenges_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.one_time_challenges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: one_time_challenges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.one_time_challenges_id_seq OWNED BY public.one_time_challenges.id;


--
-- Name: one_time_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.one_time_keys (
    id bigint NOT NULL,
    device_id bigint,
    key_id character varying DEFAULT ''::character varying NOT NULL,
    key text DEFAULT ''::text NOT NULL,
    signature text DEFAULT ''::text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: one_time_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.one_time_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: one_time_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.one_time_keys_id_seq OWNED BY public.one_time_keys.id;


--
-- Name: policies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.policies (
    id bigint NOT NULL,
    version text NOT NULL
);


--
-- Name: policies_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.policies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: policies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.policies_id_seq OWNED BY public.policies.id;


--
-- Name: preview_cards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.preview_cards (
    id bigint NOT NULL,
    url character varying DEFAULT ''::character varying NOT NULL,
    title character varying DEFAULT ''::character varying NOT NULL,
    description character varying DEFAULT ''::character varying NOT NULL,
    image_file_name character varying,
    image_content_type character varying,
    image_file_size integer,
    image_updated_at timestamp without time zone,
    type integer DEFAULT 0 NOT NULL,
    html text DEFAULT ''::text NOT NULL,
    author_name character varying DEFAULT ''::character varying NOT NULL,
    author_url character varying DEFAULT ''::character varying NOT NULL,
    provider_name character varying DEFAULT ''::character varying NOT NULL,
    provider_url character varying DEFAULT ''::character varying NOT NULL,
    width integer DEFAULT 0 NOT NULL,
    height integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    embed_url character varying DEFAULT ''::character varying NOT NULL,
    image_storage_schema_version integer,
    blurhash character varying,
    file_s3_host character varying(64)
);


--
-- Name: preview_cards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.preview_cards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: preview_cards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.preview_cards_id_seq OWNED BY public.preview_cards.id;


--
-- Name: preview_cards_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.preview_cards_statuses (
    preview_card_id bigint NOT NULL,
    status_id bigint NOT NULL
);


--
-- Name: relays; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.relays (
    id bigint NOT NULL,
    inbox_url character varying DEFAULT ''::character varying NOT NULL,
    follow_activity_id character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    state integer DEFAULT 0 NOT NULL
);


--
-- Name: relays_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.relays_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: relays_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.relays_id_seq OWNED BY public.relays.id;


--
-- Name: report_notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.report_notes (
    id bigint NOT NULL,
    content text NOT NULL,
    report_id bigint NOT NULL,
    account_id bigint NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: report_notes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.report_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: report_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.report_notes_id_seq OWNED BY public.report_notes.id;


--
-- Name: reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reports (
    status_ids bigint[] DEFAULT '{}'::integer[] NOT NULL,
    comment text DEFAULT ''::text NOT NULL,
    action_taken boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    account_id bigint NOT NULL,
    action_taken_by_account_id bigint,
    id bigint NOT NULL,
    target_account_id bigint NOT NULL,
    assigned_account_id bigint,
    uri character varying,
    forwarded boolean,
    rule_ids integer[] DEFAULT '{}'::integer[] NOT NULL,
    message_ids bigint[] DEFAULT '{}'::bigint[],
    group_id bigint,
    external_ad_id integer
);


--
-- Name: reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.reports_id_seq OWNED BY public.reports.id;


--
-- Name: rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rules (
    id bigint NOT NULL,
    priority integer DEFAULT 0 NOT NULL,
    deleted_at timestamp without time zone,
    text text DEFAULT ''::text NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    rule_type integer DEFAULT 0,
    subtext text DEFAULT ''::text NOT NULL,
    name text DEFAULT ''::text NOT NULL
);


--
-- Name: rules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rules_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rules_id_seq OWNED BY public.rules.id;


--
-- Name: scheduled_statuses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scheduled_statuses (
    id bigint NOT NULL,
    account_id bigint,
    scheduled_at timestamp without time zone,
    params jsonb
);


--
-- Name: scheduled_statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scheduled_statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scheduled_statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scheduled_statuses_id_seq OWNED BY public.scheduled_statuses.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: session_activations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.session_activations (
    id bigint NOT NULL,
    session_id character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_agent character varying DEFAULT ''::character varying NOT NULL,
    ip inet,
    access_token_id bigint,
    user_id bigint NOT NULL,
    web_push_subscription_id bigint
);


--
-- Name: session_activations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.session_activations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: session_activations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.session_activations_id_seq OWNED BY public.session_activations.id;


--
-- Name: settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settings (
    var character varying NOT NULL,
    value text,
    thing_type character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id bigint NOT NULL,
    thing_id bigint
);


--
-- Name: settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.settings_id_seq OWNED BY public.settings.id;


--
-- Name: site_uploads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.site_uploads (
    id bigint NOT NULL,
    var character varying DEFAULT ''::character varying NOT NULL,
    file_file_name character varying,
    file_content_type character varying,
    file_file_size integer,
    file_updated_at timestamp without time zone,
    meta json,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    file_s3_host character varying(64)
);


--
-- Name: site_uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.site_uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: site_uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.site_uploads_id_seq OWNED BY public.site_uploads.id;


--
-- Name: status_pins; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.status_pins (
    id bigint NOT NULL,
    account_id bigint NOT NULL,
    status_id bigint NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    pin_location public.status_pin_location DEFAULT 'profile'::public.status_pin_location NOT NULL
);


--
-- Name: status_pins_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.status_pins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: status_pins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.status_pins_id_seq OWNED BY public.status_pins.id;


--
-- Name: status_stats_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.status_stats_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: status_stats_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.status_stats_id_seq OWNED BY public.status_stats.id;


--
-- Name: statuses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.statuses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: statuses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.statuses_id_seq OWNED BY public.statuses.id;


--
-- Name: statuses_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.statuses_tags (
    status_id bigint NOT NULL,
    tag_id bigint NOT NULL
);


--
-- Name: system_keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_keys (
    id bigint NOT NULL,
    key bytea,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: system_keys_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_keys_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_keys_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.system_keys_id_seq OWNED BY public.system_keys.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    name character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    id bigint NOT NULL,
    usable boolean,
    trendable boolean DEFAULT true NOT NULL,
    listable boolean,
    reviewed_at timestamp without time zone,
    requested_review_at timestamp without time zone,
    last_status_at timestamp without time zone,
    max_score double precision,
    max_score_at timestamp without time zone
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: tombstones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tombstones (
    id bigint NOT NULL,
    account_id bigint,
    uri character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    by_moderator boolean
);


--
-- Name: tombstones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tombstones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tombstones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tombstones_id_seq OWNED BY public.tombstones.id;


--
-- Name: unavailable_domains; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.unavailable_domains (
    id bigint NOT NULL,
    domain character varying DEFAULT ''::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: unavailable_domains_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.unavailable_domains_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: unavailable_domains_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.unavailable_domains_id_seq OWNED BY public.unavailable_domains.id;


--
-- Name: user_invite_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_invite_requests (
    id bigint NOT NULL,
    user_id bigint,
    text text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: user_invite_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_invite_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_invite_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_invite_requests_id_seq OWNED BY public.user_invite_requests.id;


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: web_push_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.web_push_subscriptions (
    id bigint NOT NULL,
    endpoint character varying,
    key_p256dh character varying,
    key_auth character varying,
    data json,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    access_token_id bigint,
    user_id bigint,
    device_token character varying,
    platform integer DEFAULT 0,
    environment integer DEFAULT 0
);


--
-- Name: web_push_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.web_push_subscriptions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: web_push_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.web_push_subscriptions_id_seq OWNED BY public.web_push_subscriptions.id;


--
-- Name: web_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.web_settings (
    data json,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    id bigint NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: web_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.web_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: web_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.web_settings_id_seq OWNED BY public.web_settings.id;


--
-- Name: webauthn_credentials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.webauthn_credentials (
    id bigint NOT NULL,
    external_id character varying NOT NULL,
    public_key character varying NOT NULL,
    nickname character varying NOT NULL,
    sign_count bigint DEFAULT 0 NOT NULL,
    user_id bigint,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    receipt text,
    fraud_metric integer,
    receipt_updated_at timestamp without time zone,
    baseline_fraud_metric smallint DEFAULT 0 NOT NULL,
    sandbox boolean DEFAULT false NOT NULL
);


--
-- Name: webauthn_credentials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.webauthn_credentials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: webauthn_credentials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.webauthn_credentials_id_seq OWNED BY public.webauthn_credentials.id;


--
-- Name: account_follower_statistics; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.account_follower_statistics (
    account_id bigint NOT NULL,
    adjustment smallint NOT NULL
);

ALTER TABLE ONLY queues.account_follower_statistics REPLICA IDENTITY FULL;


--
-- Name: account_following_statistics; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.account_following_statistics (
    account_id bigint NOT NULL,
    adjustment integer NOT NULL
);

ALTER TABLE ONLY queues.account_following_statistics REPLICA IDENTITY FULL;


--
-- Name: account_index_1; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.account_index_1 (
    account_id bigint NOT NULL,
    dirty_fields text[]
);

ALTER TABLE ONLY queues.account_index_1 REPLICA IDENTITY FULL;


--
-- Name: account_index_2; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.account_index_2 (
    account_id bigint NOT NULL,
    dirty_fields text[]
);

ALTER TABLE ONLY queues.account_index_2 REPLICA IDENTITY FULL;


--
-- Name: account_index_batch_1; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.account_index_batch_1 (
    account_id bigint NOT NULL,
    dirty_fields text[]
);

ALTER TABLE ONLY queues.account_index_batch_1 REPLICA IDENTITY FULL;


--
-- Name: account_index_batch_2; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.account_index_batch_2 (
    account_id bigint NOT NULL,
    dirty_fields text[]
);

ALTER TABLE ONLY queues.account_index_batch_2 REPLICA IDENTITY FULL;


--
-- Name: account_status_statistics; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.account_status_statistics (
    account_id bigint NOT NULL,
    adjustment integer NOT NULL
);

ALTER TABLE ONLY queues.account_status_statistics REPLICA IDENTITY FULL;


--
-- Name: chat_events; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.chat_events (
    chat_id integer NOT NULL,
    "timestamp" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    event_type chat_events.event_type NOT NULL,
    payload jsonb
);

ALTER TABLE ONLY queues.chat_events REPLICA IDENTITY FULL;


--
-- Name: chat_subscribers; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.chat_subscribers (
    chat_id integer NOT NULL,
    adjustment integer NOT NULL
);

ALTER TABLE ONLY queues.chat_subscribers REPLICA IDENTITY FULL;


--
-- Name: poll_option_statistics; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.poll_option_statistics (
    poll_id bigint NOT NULL,
    option_number smallint NOT NULL,
    adjustment integer NOT NULL
);

ALTER TABLE ONLY queues.poll_option_statistics REPLICA IDENTITY FULL;


--
-- Name: reply_status_controversial_scores; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.reply_status_controversial_scores (
    status_id bigint NOT NULL,
    priority boolean DEFAULT true NOT NULL
);

ALTER TABLE ONLY queues.reply_status_controversial_scores REPLICA IDENTITY FULL;


--
-- Name: reply_status_trending_scores; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.reply_status_trending_scores (
    status_id bigint NOT NULL,
    priority boolean DEFAULT true NOT NULL
);

ALTER TABLE ONLY queues.reply_status_trending_scores REPLICA IDENTITY FULL;


--
-- Name: status_distribution_batch_br2; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.status_distribution_batch_br2 (
    status_id bigint NOT NULL,
    distribution_type queues.distribution_type
);

ALTER TABLE ONLY queues.status_distribution_batch_br2 REPLICA IDENTITY FULL;


--
-- Name: status_distribution_batch_or1; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.status_distribution_batch_or1 (
    status_id bigint NOT NULL,
    distribution_type queues.distribution_type
);

ALTER TABLE ONLY queues.status_distribution_batch_or1 REPLICA IDENTITY FULL;


--
-- Name: status_distribution_br2; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.status_distribution_br2 (
    status_id bigint NOT NULL,
    distribution_type queues.distribution_type
);

ALTER TABLE ONLY queues.status_distribution_br2 REPLICA IDENTITY FULL;


--
-- Name: status_distribution_or1; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.status_distribution_or1 (
    status_id bigint NOT NULL,
    distribution_type queues.distribution_type
);

ALTER TABLE ONLY queues.status_distribution_or1 REPLICA IDENTITY FULL;


--
-- Name: status_engagement_statistics; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.status_engagement_statistics (
    status_id bigint NOT NULL,
    priority boolean DEFAULT true NOT NULL
);

ALTER TABLE ONLY queues.status_engagement_statistics REPLICA IDENTITY FULL;


--
-- Name: status_favourite_statistics; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.status_favourite_statistics (
    status_id bigint NOT NULL,
    adjustment integer NOT NULL,
    priority boolean DEFAULT true NOT NULL
);

ALTER TABLE ONLY queues.status_favourite_statistics REPLICA IDENTITY FULL;


--
-- Name: status_index_1; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.status_index_1 (
    status_id bigint NOT NULL
);

ALTER TABLE ONLY queues.status_index_1 REPLICA IDENTITY FULL;


--
-- Name: status_index_2; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.status_index_2 (
    status_id bigint NOT NULL
);

ALTER TABLE ONLY queues.status_index_2 REPLICA IDENTITY FULL;


--
-- Name: status_index_batch_1; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.status_index_batch_1 (
    status_id bigint NOT NULL
);

ALTER TABLE ONLY queues.status_index_batch_1 REPLICA IDENTITY FULL;


--
-- Name: status_index_batch_2; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.status_index_batch_2 (
    status_id bigint NOT NULL
);

ALTER TABLE ONLY queues.status_index_batch_2 REPLICA IDENTITY FULL;


--
-- Name: status_reblog_statistics; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.status_reblog_statistics (
    status_id bigint NOT NULL,
    priority boolean DEFAULT true NOT NULL
);

ALTER TABLE ONLY queues.status_reblog_statistics REPLICA IDENTITY FULL;


--
-- Name: status_reply_statistics; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.status_reply_statistics (
    status_id bigint NOT NULL,
    priority boolean DEFAULT true NOT NULL
);

ALTER TABLE ONLY queues.status_reply_statistics REPLICA IDENTITY FULL;


--
-- Name: tag_index_1; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.tag_index_1 (
    tag_id bigint NOT NULL
);

ALTER TABLE ONLY queues.tag_index_1 REPLICA IDENTITY FULL;


--
-- Name: tag_index_2; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.tag_index_2 (
    tag_id bigint NOT NULL
);

ALTER TABLE ONLY queues.tag_index_2 REPLICA IDENTITY FULL;


--
-- Name: tag_index_batch_1; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.tag_index_batch_1 (
    tag_id bigint NOT NULL
);

ALTER TABLE ONLY queues.tag_index_batch_1 REPLICA IDENTITY FULL;


--
-- Name: tag_index_batch_2; Type: TABLE; Schema: queues; Owner: -
--

CREATE TABLE queues.tag_index_batch_2 (
    tag_id bigint NOT NULL
);

ALTER TABLE ONLY queues.tag_index_batch_2 REPLICA IDENTITY FULL;


--
-- Name: account_suppressions; Type: TABLE; Schema: recommendations; Owner: -
--

CREATE TABLE recommendations.account_suppressions (
    account_id bigint NOT NULL,
    target_account_id bigint NOT NULL,
    status_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP) NOT NULL
);


--
-- Name: follows; Type: TABLE; Schema: recommendations; Owner: -
--

CREATE TABLE recommendations.follows (
    account_id bigint NOT NULL,
    target_account_ids bigint[] NOT NULL
);


--
-- Name: group_suppressions; Type: TABLE; Schema: recommendations; Owner: -
--

CREATE TABLE recommendations.group_suppressions (
    account_id bigint NOT NULL,
    group_id bigint NOT NULL,
    status_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP) NOT NULL
);


--
-- Name: statuses; Type: TABLE; Schema: recommendations; Owner: -
--

CREATE TABLE recommendations.statuses (
    account_id bigint NOT NULL,
    status_ids bigint[] NOT NULL
);


--
-- Name: emojis; Type: TABLE; Schema: reference; Owner: -
--

CREATE TABLE reference.emojis (
    emoji_id smallint NOT NULL,
    emoji text NOT NULL
);


--
-- Name: emojis_emoji_id_seq; Type: SEQUENCE; Schema: reference; Owner: -
--

ALTER TABLE reference.emojis ALTER COLUMN emoji_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME reference.emojis_emoji_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: one_time_challenges; Type: TABLE; Schema: registrations; Owner: -
--

CREATE TABLE registrations.one_time_challenges (
    registration_id bigint NOT NULL,
    one_time_challenge_id bigint NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP) NOT NULL
);


--
-- Name: registrations; Type: TABLE; Schema: registrations; Owner: -
--

CREATE TABLE registrations.registrations (
    registration_id bigint NOT NULL,
    token text NOT NULL,
    platform_id smallint NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP) NOT NULL,
    updated_at timestamp without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP) NOT NULL
);


--
-- Name: registrations_registration_id_seq; Type: SEQUENCE; Schema: registrations; Owner: -
--

ALTER TABLE registrations.registrations ALTER COLUMN registration_id ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME registrations.registrations_registration_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: webauthn_credentials; Type: TABLE; Schema: registrations; Owner: -
--

CREATE TABLE registrations.webauthn_credentials (
    registration_id bigint NOT NULL,
    webauthn_credential_id bigint NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP) NOT NULL
);


--
-- Name: daily_active_user_counts; Type: TABLE; Schema: statistics; Owner: -
--

CREATE TABLE statistics.daily_active_user_counts (
    date date NOT NULL,
    count integer NOT NULL
);


--
-- Name: daily_active_users; Type: TABLE; Schema: statistics; Owner: -
--

CREATE TABLE statistics.daily_active_users (
    date date NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: poll_options; Type: TABLE; Schema: statistics; Owner: -
--

CREATE TABLE statistics.poll_options (
    poll_id integer NOT NULL,
    option_number smallint NOT NULL,
    votes integer NOT NULL
);


--
-- Name: polls; Type: TABLE; Schema: statistics; Owner: -
--

CREATE TABLE statistics.polls (
    poll_id integer NOT NULL,
    votes integer NOT NULL,
    voters integer NOT NULL
);


--
-- Name: reply_status_controversial_scores; Type: TABLE; Schema: statistics; Owner: -
--

CREATE TABLE statistics.reply_status_controversial_scores (
    status_id bigint NOT NULL,
    reply_to_status_id bigint NOT NULL,
    score bigint DEFAULT 0 NOT NULL
);


--
-- Name: reply_status_trending_scores; Type: TABLE; Schema: statistics; Owner: -
--

CREATE TABLE statistics.reply_status_trending_scores (
    status_id bigint NOT NULL,
    reply_to_status_id bigint NOT NULL,
    score bigint DEFAULT 0 NOT NULL
);


--
-- Name: status_engagement; Type: TABLE; Schema: statistics; Owner: -
--

CREATE TABLE statistics.status_engagement (
    status_id bigint NOT NULL,
    engagers_count integer NOT NULL
);


--
-- Name: status_view_counts; Type: TABLE; Schema: statistics; Owner: -
--

CREATE TABLE statistics.status_view_counts (
    status_id bigint NOT NULL,
    total_count bigint NOT NULL,
    unique_count bigint NOT NULL
);


--
-- Name: analysis; Type: TABLE; Schema: statuses; Owner: -
--

CREATE TABLE statuses.analysis (
    status_id bigint NOT NULL,
    spam_score smallint DEFAULT 0 NOT NULL
);


--
-- Name: moderation_results; Type: TABLE; Schema: statuses; Owner: -
--

CREATE TABLE statuses.moderation_results (
    status_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    moderation_result statuses.moderation_result NOT NULL
);


--
-- Name: excluded_groups; Type: TABLE; Schema: trending_groups; Owner: -
--

CREATE TABLE trending_groups.excluded_groups (
    group_id bigint NOT NULL
);


--
-- Name: trending_group_scores; Type: MATERIALIZED VIEW; Schema: trending_groups; Owner: -
--

CREATE MATERIALIZED VIEW trending_groups.trending_group_scores AS
 SELECT group_id,
    score
   FROM trending_groups.trending_group_scores() trending_group_scores(group_id, score)
  WITH NO DATA;


--
-- Name: recent_statuses_from_followed_accounts; Type: MATERIALIZED VIEW; Schema: trending_statuses; Owner: -
--

CREATE MATERIALIZED VIEW trending_statuses.recent_statuses_from_followed_accounts AS
 SELECT status_id,
    account_id
   FROM trending_statuses.recent_statuses_from_followed_accounts() recent_statuses_from_followed_accounts(status_id, account_id)
  WITH NO DATA;


--
-- Name: favourites_by_nonfollowers; Type: MATERIALIZED VIEW; Schema: trending_statuses; Owner: -
--

CREATE MATERIALIZED VIEW trending_statuses.favourites_by_nonfollowers AS
 SELECT status_id,
    trending_statuses.status_favourites_by_nonfollowers(status_id) AS favourites_count
   FROM trending_statuses.recent_statuses_from_followed_accounts
  WHERE (trending_statuses.status_favourites_by_nonfollowers(status_id) > 0)
  WITH NO DATA;


--
-- Name: reblogs_by_nonfollowers; Type: MATERIALIZED VIEW; Schema: trending_statuses; Owner: -
--

CREATE MATERIALIZED VIEW trending_statuses.reblogs_by_nonfollowers AS
 SELECT status_id,
    trending_statuses.status_reblogs_by_nonfollowers(status_id) AS reblogs_count
   FROM trending_statuses.recent_statuses_from_followed_accounts
  WHERE (trending_statuses.status_reblogs_by_nonfollowers(status_id) > 0)
  WITH NO DATA;


--
-- Name: replies_by_nonfollowers; Type: MATERIALIZED VIEW; Schema: trending_statuses; Owner: -
--

CREATE MATERIALIZED VIEW trending_statuses.replies_by_nonfollowers AS
 SELECT status_id,
    trending_statuses.status_replies_by_nonfollowers(status_id) AS replies_count
   FROM trending_statuses.recent_statuses_from_followed_accounts
  WHERE (trending_statuses.status_replies_by_nonfollowers(status_id) > 0)
  WITH NO DATA;


--
-- Name: trending_statuses_popular_information; Type: VIEW; Schema: trending_statuses; Owner: -
--

CREATE VIEW trending_statuses.trending_statuses_popular_information AS
 SELECT t.status_id,
    s.uri,
    r.replies_count,
    b.reblogs_count,
    f.favourites_count,
    w.followers_count,
    t.rank
   FROM (((((trending_statuses.trending_statuses_popular t
     JOIN public.statuses s ON ((s.id = t.status_id)))
     JOIN statistics.status_replies r USING (status_id))
     JOIN statistics.status_reblogs b USING (status_id))
     JOIN statistics.status_favourites f USING (status_id))
     JOIN statistics.account_followers w USING (account_id))
  ORDER BY t.rank DESC;


--
-- Name: trending_statuses_viral_information; Type: VIEW; Schema: trending_statuses; Owner: -
--

CREATE VIEW trending_statuses.trending_statuses_viral_information AS
 SELECT t.status_id,
    s.uri,
    r.replies_count,
    b.reblogs_count,
    f.favourites_count,
    w.followers_count,
    t.rank
   FROM (((((trending_statuses.trending_statuses_viral t
     JOIN public.statuses s ON ((s.id = t.status_id)))
     JOIN trending_statuses.replies_by_nonfollowers r USING (status_id))
     JOIN trending_statuses.reblogs_by_nonfollowers b USING (status_id))
     JOIN trending_statuses.favourites_by_nonfollowers f USING (status_id))
     JOIN statistics.account_followers w USING (account_id))
  ORDER BY t.rank DESC;


--
-- Name: trending_tag_scores; Type: MATERIALIZED VIEW; Schema: trending_tags; Owner: -
--

CREATE MATERIALIZED VIEW trending_tags.trending_tag_scores AS
 SELECT tag_id,
    score
   FROM trending_tags.trending_tag_scores() trending_tag_scores(tag_id, score)
  WITH NO DATA;


--
-- Name: trending_tags; Type: MATERIALIZED VIEW; Schema: trending_tags; Owner: -
--

CREATE MATERIALIZED VIEW trending_tags.trending_tags AS
 SELECT row_number() OVER (ORDER BY score DESC, tag_id) AS sort_order,
    mastodon_logic.tag_statistics(tag_id) AS tag_statistics
   FROM trending_tags.trending_tag_scores
  WITH NO DATA;


--
-- Name: accounts; Type: TABLE; Schema: tv; Owner: -
--

CREATE TABLE tv.accounts (
    account_id bigint NOT NULL,
    account_uuid uuid NOT NULL,
    p_profile_id bigint
);


--
-- Name: channel_accounts; Type: TABLE; Schema: tv; Owner: -
--

CREATE TABLE tv.channel_accounts (
    channel_id smallint NOT NULL,
    account_id bigint NOT NULL
);


--
-- Name: channels; Type: TABLE; Schema: tv; Owner: -
--

CREATE TABLE tv.channels (
    channel_id smallint NOT NULL,
    name text NOT NULL,
    image_url text NOT NULL,
    pltv_timespan bigint DEFAULT 0 NOT NULL,
    enabled boolean DEFAULT false NOT NULL,
    default_program_image_url text DEFAULT 'default.png'::text NOT NULL
);


--
-- Name: deleted_accounts; Type: TABLE; Schema: tv; Owner: -
--

CREATE TABLE tv.deleted_accounts (
    p_profile_id bigint NOT NULL
);


--
-- Name: device_sessions; Type: TABLE; Schema: tv; Owner: -
--

CREATE TABLE tv.device_sessions (
    oauth_access_token_id bigint NOT NULL,
    tv_session_id text NOT NULL
);


--
-- Name: program_statuses; Type: TABLE; Schema: tv; Owner: -
--

CREATE TABLE tv.program_statuses (
    channel_id smallint NOT NULL,
    start_time timestamp with time zone NOT NULL,
    status_id bigint NOT NULL
);


--
-- Name: programs; Type: TABLE; Schema: tv; Owner: -
--

CREATE TABLE tv.programs (
    channel_id smallint NOT NULL,
    name text NOT NULL,
    image_url text NOT NULL,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL,
    description text DEFAULT ''::text NOT NULL
);


--
-- Name: programs_temporary; Type: TABLE; Schema: tv; Owner: -
--

CREATE TABLE tv.programs_temporary (
    channel_id smallint NOT NULL,
    name text NOT NULL,
    image_url text NOT NULL,
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone NOT NULL,
    description text NOT NULL
);


--
-- Name: reminders; Type: TABLE; Schema: tv; Owner: -
--

CREATE TABLE tv.reminders (
    account_id bigint NOT NULL,
    channel_id smallint NOT NULL,
    start_time timestamp with time zone NOT NULL
);


--
-- Name: statuses; Type: TABLE; Schema: tv; Owner: -
--

CREATE TABLE tv.statuses (
    status_id bigint NOT NULL
);


--
-- Name: base_emails; Type: TABLE; Schema: users; Owner: -
--

CREATE TABLE users.base_emails (
    user_id bigint NOT NULL,
    email text NOT NULL
);


--
-- Name: current_information; Type: TABLE; Schema: users; Owner: -
--

CREATE TABLE users.current_information (
    user_id bigint NOT NULL,
    current_sign_in_at timestamp(0) with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    current_sign_in_ip inet NOT NULL,
    current_city_id integer NOT NULL,
    current_country_id integer NOT NULL
);


--
-- Name: one_time_challenges; Type: TABLE; Schema: users; Owner: -
--

CREATE TABLE users.one_time_challenges (
    user_id bigint NOT NULL,
    one_time_challenge_id bigint NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('UTC'::text, CURRENT_TIMESTAMP) NOT NULL
);


--
-- Name: password_histories; Type: TABLE; Schema: users; Owner: -
--

CREATE TABLE users.password_histories (
    user_id bigint NOT NULL,
    encrypted_password text NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sms_reverification_required; Type: TABLE; Schema: users; Owner: -
--

CREATE TABLE users.sms_reverification_required (
    user_id bigint NOT NULL
);


--
-- Name: part_1; Type: TABLE ATTACH; Schema: notifications; Owner: -
--

ALTER TABLE ONLY public.notifications ATTACH PARTITION notifications.part_1 FOR VALUES FROM (0) TO (1);


--
-- Name: part_2; Type: TABLE ATTACH; Schema: notifications; Owner: -
--

ALTER TABLE ONLY public.notifications ATTACH PARTITION notifications.part_2 FOR VALUES FROM (1) TO (2);


--
-- Name: part_3; Type: TABLE ATTACH; Schema: notifications; Owner: -
--

ALTER TABLE ONLY public.notifications ATTACH PARTITION notifications.part_3 FOR VALUES FROM (2) TO (3);


--
-- Name: part_4; Type: TABLE ATTACH; Schema: notifications; Owner: -
--

ALTER TABLE ONLY public.notifications ATTACH PARTITION notifications.part_4 FOR VALUES FROM (3) TO (4);


--
-- Name: part_5; Type: TABLE ATTACH; Schema: notifications; Owner: -
--

ALTER TABLE ONLY public.notifications ATTACH PARTITION notifications.part_5 FOR VALUES FROM (4) TO (5);


--
-- Name: part_6; Type: TABLE ATTACH; Schema: notifications; Owner: -
--

ALTER TABLE ONLY public.notifications ATTACH PARTITION notifications.part_6 FOR VALUES FROM (5) TO (6);


--
-- Name: chat_members accepted; Type: DEFAULT; Schema: api; Owner: -
--

ALTER TABLE ONLY api.chat_members ALTER COLUMN accepted SET DEFAULT false;


--
-- Name: chat_members active; Type: DEFAULT; Schema: api; Owner: -
--

ALTER TABLE ONLY api.chat_members ALTER COLUMN active SET DEFAULT true;


--
-- Name: chat_members silenced; Type: DEFAULT; Schema: api; Owner: -
--

ALTER TABLE ONLY api.chat_members ALTER COLUMN silenced SET DEFAULT false;


--
-- Name: chat_members latest_read_message_created_at; Type: DEFAULT; Schema: api; Owner: -
--

ALTER TABLE ONLY api.chat_members ALTER COLUMN latest_read_message_created_at SET DEFAULT CURRENT_TIMESTAMP;


--
-- Name: chats message_expiration; Type: DEFAULT; Schema: api; Owner: -
--

ALTER TABLE ONLY api.chats ALTER COLUMN message_expiration SET DEFAULT '14 days'::interval;


--
-- Name: account_aliases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_aliases ALTER COLUMN id SET DEFAULT nextval('public.account_aliases_id_seq'::regclass);


--
-- Name: account_conversations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_conversations ALTER COLUMN id SET DEFAULT nextval('public.account_conversations_id_seq'::regclass);


--
-- Name: account_deletion_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_deletion_requests ALTER COLUMN id SET DEFAULT nextval('public.account_deletion_requests_id_seq'::regclass);


--
-- Name: account_domain_blocks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_domain_blocks ALTER COLUMN id SET DEFAULT nextval('public.account_domain_blocks_id_seq'::regclass);


--
-- Name: account_identity_proofs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_identity_proofs ALTER COLUMN id SET DEFAULT nextval('public.account_identity_proofs_id_seq'::regclass);


--
-- Name: account_migrations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_migrations ALTER COLUMN id SET DEFAULT nextval('public.account_migrations_id_seq'::regclass);


--
-- Name: account_moderation_notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_moderation_notes ALTER COLUMN id SET DEFAULT nextval('public.account_moderation_notes_id_seq'::regclass);


--
-- Name: account_notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_notes ALTER COLUMN id SET DEFAULT nextval('public.account_notes_id_seq'::regclass);


--
-- Name: account_pins id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_pins ALTER COLUMN id SET DEFAULT nextval('public.account_pins_id_seq'::regclass);


--
-- Name: account_stats id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_stats ALTER COLUMN id SET DEFAULT nextval('public.account_stats_id_seq'::regclass);


--
-- Name: account_warning_presets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_warning_presets ALTER COLUMN id SET DEFAULT nextval('public.account_warning_presets_id_seq'::regclass);


--
-- Name: account_warnings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_warnings ALTER COLUMN id SET DEFAULT nextval('public.account_warnings_id_seq'::regclass);


--
-- Name: admin_action_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_action_logs ALTER COLUMN id SET DEFAULT nextval('public.admin_action_logs_id_seq'::regclass);


--
-- Name: announcement_mutes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcement_mutes ALTER COLUMN id SET DEFAULT nextval('public.announcement_mutes_id_seq'::regclass);


--
-- Name: announcement_reactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcement_reactions ALTER COLUMN id SET DEFAULT nextval('public.announcement_reactions_id_seq'::regclass);


--
-- Name: announcements id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements ALTER COLUMN id SET DEFAULT nextval('public.announcements_id_seq'::regclass);


--
-- Name: backups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.backups ALTER COLUMN id SET DEFAULT nextval('public.backups_id_seq'::regclass);


--
-- Name: blocks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocks ALTER COLUMN id SET DEFAULT nextval('public.blocks_id_seq'::regclass);


--
-- Name: bookmarks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookmarks ALTER COLUMN id SET DEFAULT nextval('public.bookmarks_id_seq'::regclass);


--
-- Name: canonical_email_blocks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.canonical_email_blocks ALTER COLUMN id SET DEFAULT nextval('public.canonical_email_blocks_id_seq'::regclass);


--
-- Name: conversation_mutes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_mutes ALTER COLUMN id SET DEFAULT nextval('public.conversation_mutes_id_seq'::regclass);


--
-- Name: conversations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations ALTER COLUMN id SET DEFAULT nextval('public.conversations_id_seq'::regclass);


--
-- Name: csv_exports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.csv_exports ALTER COLUMN id SET DEFAULT nextval('public.csv_exports_id_seq'::regclass);


--
-- Name: custom_emoji_categories id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_emoji_categories ALTER COLUMN id SET DEFAULT nextval('public.custom_emoji_categories_id_seq'::regclass);


--
-- Name: custom_emojis id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_emojis ALTER COLUMN id SET DEFAULT nextval('public.custom_emojis_id_seq'::regclass);


--
-- Name: custom_filters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_filters ALTER COLUMN id SET DEFAULT nextval('public.custom_filters_id_seq'::regclass);


--
-- Name: devices id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devices ALTER COLUMN id SET DEFAULT nextval('public.devices_id_seq'::regclass);


--
-- Name: domain_allows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.domain_allows ALTER COLUMN id SET DEFAULT nextval('public.domain_allows_id_seq'::regclass);


--
-- Name: domain_blocks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.domain_blocks ALTER COLUMN id SET DEFAULT nextval('public.domain_blocks_id_seq'::regclass);


--
-- Name: email_domain_blocks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_domain_blocks ALTER COLUMN id SET DEFAULT nextval('public.email_domain_blocks_id_seq'::regclass);


--
-- Name: favourites id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favourites ALTER COLUMN id SET DEFAULT nextval('public.favourites_id_seq'::regclass);


--
-- Name: featured_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.featured_tags ALTER COLUMN id SET DEFAULT nextval('public.featured_tags_id_seq'::regclass);


--
-- Name: follow_deletes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follow_deletes ALTER COLUMN id SET DEFAULT nextval('public.follow_deletes_id_seq'::regclass);


--
-- Name: follow_recommendation_suppressions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follow_recommendation_suppressions ALTER COLUMN id SET DEFAULT nextval('public.follow_recommendation_suppressions_id_seq'::regclass);


--
-- Name: follow_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follow_requests ALTER COLUMN id SET DEFAULT nextval('public.follow_requests_id_seq'::regclass);


--
-- Name: follows id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follows ALTER COLUMN id SET DEFAULT nextval('public.follows_id_seq'::regclass);


--
-- Name: group_account_blocks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_account_blocks ALTER COLUMN id SET DEFAULT nextval('public.group_account_blocks_id_seq'::regclass);


--
-- Name: group_deletion_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_deletion_requests ALTER COLUMN id SET DEFAULT nextval('public.group_deletion_requests_id_seq'::regclass);


--
-- Name: group_membership_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_membership_requests ALTER COLUMN id SET DEFAULT nextval('public.group_membership_requests_id_seq'::regclass);


--
-- Name: group_memberships id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_memberships ALTER COLUMN id SET DEFAULT nextval('public.group_memberships_id_seq'::regclass);


--
-- Name: group_stats id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_stats ALTER COLUMN id SET DEFAULT nextval('public.group_stats_id_seq'::regclass);


--
-- Name: group_suggestions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_suggestions ALTER COLUMN id SET DEFAULT nextval('public.group_suggestions_id_seq'::regclass);


--
-- Name: identities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identities ALTER COLUMN id SET DEFAULT nextval('public.identities_id_seq'::regclass);


--
-- Name: imports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imports ALTER COLUMN id SET DEFAULT nextval('public.imports_id_seq'::regclass);


--
-- Name: invites id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invites ALTER COLUMN id SET DEFAULT nextval('public.invites_id_seq'::regclass);


--
-- Name: ip_blocks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ip_blocks ALTER COLUMN id SET DEFAULT nextval('public.ip_blocks_id_seq'::regclass);


--
-- Name: list_accounts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.list_accounts ALTER COLUMN id SET DEFAULT nextval('public.list_accounts_id_seq'::regclass);


--
-- Name: lists id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lists ALTER COLUMN id SET DEFAULT nextval('public.lists_id_seq'::regclass);


--
-- Name: logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs ALTER COLUMN id SET DEFAULT nextval('public.logs_id_seq'::regclass);


--
-- Name: markers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.markers ALTER COLUMN id SET DEFAULT nextval('public.markers_id_seq'::regclass);


--
-- Name: mentions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mentions ALTER COLUMN id SET DEFAULT nextval('public.mentions_id_seq'::regclass);


--
-- Name: moderation_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderation_records ALTER COLUMN id SET DEFAULT nextval('public.moderation_records_id_seq'::regclass);


--
-- Name: mutes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mutes ALTER COLUMN id SET DEFAULT nextval('public.mutes_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: oauth_access_grants id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants ALTER COLUMN id SET DEFAULT nextval('public.oauth_access_grants_id_seq'::regclass);


--
-- Name: oauth_access_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens ALTER COLUMN id SET DEFAULT nextval('public.oauth_access_tokens_id_seq'::regclass);


--
-- Name: oauth_applications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_applications ALTER COLUMN id SET DEFAULT nextval('public.oauth_applications_id_seq'::regclass);


--
-- Name: one_time_challenges id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.one_time_challenges ALTER COLUMN id SET DEFAULT nextval('public.one_time_challenges_id_seq'::regclass);


--
-- Name: one_time_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.one_time_keys ALTER COLUMN id SET DEFAULT nextval('public.one_time_keys_id_seq'::regclass);


--
-- Name: policies id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.policies ALTER COLUMN id SET DEFAULT nextval('public.policies_id_seq'::regclass);


--
-- Name: preview_cards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preview_cards ALTER COLUMN id SET DEFAULT nextval('public.preview_cards_id_seq'::regclass);


--
-- Name: relays id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relays ALTER COLUMN id SET DEFAULT nextval('public.relays_id_seq'::regclass);


--
-- Name: report_notes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_notes ALTER COLUMN id SET DEFAULT nextval('public.report_notes_id_seq'::regclass);


--
-- Name: reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports ALTER COLUMN id SET DEFAULT nextval('public.reports_id_seq'::regclass);


--
-- Name: rules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rules ALTER COLUMN id SET DEFAULT nextval('public.rules_id_seq'::regclass);


--
-- Name: scheduled_statuses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduled_statuses ALTER COLUMN id SET DEFAULT nextval('public.scheduled_statuses_id_seq'::regclass);


--
-- Name: session_activations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_activations ALTER COLUMN id SET DEFAULT nextval('public.session_activations_id_seq'::regclass);


--
-- Name: settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings ALTER COLUMN id SET DEFAULT nextval('public.settings_id_seq'::regclass);


--
-- Name: site_uploads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_uploads ALTER COLUMN id SET DEFAULT nextval('public.site_uploads_id_seq'::regclass);


--
-- Name: status_pins id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_pins ALTER COLUMN id SET DEFAULT nextval('public.status_pins_id_seq'::regclass);


--
-- Name: status_stats id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_stats ALTER COLUMN id SET DEFAULT nextval('public.status_stats_id_seq'::regclass);


--
-- Name: system_keys id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_keys ALTER COLUMN id SET DEFAULT nextval('public.system_keys_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: tombstones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tombstones ALTER COLUMN id SET DEFAULT nextval('public.tombstones_id_seq'::regclass);


--
-- Name: unavailable_domains id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unavailable_domains ALTER COLUMN id SET DEFAULT nextval('public.unavailable_domains_id_seq'::regclass);


--
-- Name: user_invite_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_invite_requests ALTER COLUMN id SET DEFAULT nextval('public.user_invite_requests_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: web_push_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_push_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.web_push_subscriptions_id_seq'::regclass);


--
-- Name: web_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_settings ALTER COLUMN id SET DEFAULT nextval('public.web_settings_id_seq'::regclass);


--
-- Name: webauthn_credentials id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webauthn_credentials ALTER COLUMN id SET DEFAULT nextval('public.webauthn_credentials_id_seq'::regclass);


--
-- Name: group_status_tags group_status_tags_pkey; Type: CONSTRAINT; Schema: cache; Owner: -
--

ALTER TABLE ONLY cache.group_status_tags
    ADD CONSTRAINT group_status_tags_pkey PRIMARY KEY (status_id, tag_id);


--
-- Name: status_tags status_tags_pkey; Type: CONSTRAINT; Schema: cache; Owner: -
--

ALTER TABLE ONLY cache.status_tags
    ADD CONSTRAINT status_tags_pkey PRIMARY KEY (status_id, tag_id);


--
-- Name: chat_message_expiration_changes chat_message_expiration_changes_pkey; Type: CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.chat_message_expiration_changes
    ADD CONSTRAINT chat_message_expiration_changes_pkey PRIMARY KEY (event_id);


--
-- Name: chat_silences chat_silences_pkey; Type: CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.chat_silences
    ADD CONSTRAINT chat_silences_pkey PRIMARY KEY (event_id);


--
-- Name: chat_unsilences chat_unsilences_pkey; Type: CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.chat_unsilences
    ADD CONSTRAINT chat_unsilences_pkey PRIMARY KEY (event_id);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (event_id);


--
-- Name: member_avatar_changes member_avatar_changes_pkey; Type: CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.member_avatar_changes
    ADD CONSTRAINT member_avatar_changes_pkey PRIMARY KEY (event_id);


--
-- Name: member_invitations member_invitations_pkey; Type: CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.member_invitations
    ADD CONSTRAINT member_invitations_pkey PRIMARY KEY (event_id);


--
-- Name: member_joins member_joins_pkey; Type: CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.member_joins
    ADD CONSTRAINT member_joins_pkey PRIMARY KEY (event_id);


--
-- Name: member_latest_read_message_changes member_latest_read_message_changes_pkey; Type: CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.member_latest_read_message_changes
    ADD CONSTRAINT member_latest_read_message_changes_pkey PRIMARY KEY (event_id);


--
-- Name: member_leaves member_leaves_pkey; Type: CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.member_leaves
    ADD CONSTRAINT member_leaves_pkey PRIMARY KEY (event_id);


--
-- Name: member_rejoins member_rejoins_pkey; Type: CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.member_rejoins
    ADD CONSTRAINT member_rejoins_pkey PRIMARY KEY (event_id);


--
-- Name: message_creations message_creations_pkey; Type: CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.message_creations
    ADD CONSTRAINT message_creations_pkey PRIMARY KEY (event_id);


--
-- Name: message_deletions message_deletions_pkey; Type: CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.message_deletions
    ADD CONSTRAINT message_deletions_pkey PRIMARY KEY (event_id);


--
-- Name: message_edits message_edits_pkey; Type: CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.message_edits
    ADD CONSTRAINT message_edits_pkey PRIMARY KEY (event_id);


--
-- Name: message_hides message_hides_pkey; Type: CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.message_hides
    ADD CONSTRAINT message_hides_pkey PRIMARY KEY (event_id);


--
-- Name: message_reactions_changes message_reactions_changes_pkey; Type: CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.message_reactions_changes
    ADD CONSTRAINT message_reactions_changes_pkey PRIMARY KEY (event_id);


--
-- Name: subscriber_leaves subscriber_leaves_pkey; Type: CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.subscriber_leaves
    ADD CONSTRAINT subscriber_leaves_pkey PRIMARY KEY (event_id);


--
-- Name: subscriber_rejoins subscriber_rejoins_pkey; Type: CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.subscriber_rejoins
    ADD CONSTRAINT subscriber_rejoins_pkey PRIMARY KEY (event_id);


--
-- Name: chat_message_expiration_changes chat_message_expiration_changes_pkey; Type: CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.chat_message_expiration_changes
    ADD CONSTRAINT chat_message_expiration_changes_pkey PRIMARY KEY (chat_id, changed_at);


--
-- Name: chats chats_pkey; Type: CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.chats
    ADD CONSTRAINT chats_pkey PRIMARY KEY (chat_id);


--
-- Name: deleted_chats deleted_chats_pkey; Type: CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.deleted_chats
    ADD CONSTRAINT deleted_chats_pkey PRIMARY KEY (chat_id);


--
-- Name: deleted_members deleted_members_pkey; Type: CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.deleted_members
    ADD CONSTRAINT deleted_members_pkey PRIMARY KEY (chat_id, account_id);


--
-- Name: deleted_message_text deleted_message_text_pkey; Type: CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.deleted_message_text
    ADD CONSTRAINT deleted_message_text_pkey PRIMARY KEY (message_id);


--
-- Name: deleted_messages deleted_messages_pkey; Type: CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.deleted_messages
    ADD CONSTRAINT deleted_messages_pkey PRIMARY KEY (message_id);


--
-- Name: hidden_messages hidden_messages_pkey; Type: CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.hidden_messages
    ADD CONSTRAINT hidden_messages_pkey PRIMARY KEY (account_id, message_id);


--
-- Name: latest_message_reactions latest_message_reactions_pkey; Type: CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.latest_message_reactions
    ADD CONSTRAINT latest_message_reactions_pkey PRIMARY KEY (message_id);


--
-- Name: member_lists member_lists_pkey; Type: CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.member_lists
    ADD CONSTRAINT member_lists_pkey PRIMARY KEY (chat_id);


--
-- Name: members members_pkey; Type: CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.members
    ADD CONSTRAINT members_pkey PRIMARY KEY (chat_id, account_id);


--
-- Name: message_idempotency_keys message_idempotency_keys_oauth_access_token_id_idempotency__key; Type: CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.message_idempotency_keys
    ADD CONSTRAINT message_idempotency_keys_oauth_access_token_id_idempotency__key UNIQUE (oauth_access_token_id, idempotency_key);


--
-- Name: message_idempotency_keys message_idempotency_keys_pkey; Type: CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.message_idempotency_keys
    ADD CONSTRAINT message_idempotency_keys_pkey PRIMARY KEY (message_id);


--
-- Name: message_media_attachments message_media_attachments_pkey; Type: CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.message_media_attachments
    ADD CONSTRAINT message_media_attachments_pkey PRIMARY KEY (message_id, media_attachment_id);


--
-- Name: message_text message_text_pkey; Type: CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.message_text
    ADD CONSTRAINT message_text_pkey PRIMARY KEY (message_id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (message_id);


--
-- Name: reactions reactions_pkey; Type: CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.reactions
    ADD CONSTRAINT reactions_pkey PRIMARY KEY (message_id, emoji_id, account_id);


--
-- Name: subscriber_counts subscriber_counts_pkey; Type: CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.subscriber_counts
    ADD CONSTRAINT subscriber_counts_pkey PRIMARY KEY (chat_id);


--
-- Name: account_enabled_features account_enabled_features_pkey; Type: CONSTRAINT; Schema: configuration; Owner: -
--

ALTER TABLE ONLY configuration.account_enabled_features
    ADD CONSTRAINT account_enabled_features_pkey PRIMARY KEY (account_id, feature_flag_id);


--
-- Name: banned_words banned_words_pkey; Type: CONSTRAINT; Schema: configuration; Owner: -
--

ALTER TABLE ONLY configuration.banned_words
    ADD CONSTRAINT banned_words_pkey PRIMARY KEY (id);


--
-- Name: banned_words banned_words_word_key; Type: CONSTRAINT; Schema: configuration; Owner: -
--

ALTER TABLE ONLY configuration.banned_words
    ADD CONSTRAINT banned_words_word_key UNIQUE (word);


--
-- Name: elwood elwood_pkey; Type: CONSTRAINT; Schema: configuration; Owner: -
--

ALTER TABLE ONLY configuration.elwood
    ADD CONSTRAINT elwood_pkey PRIMARY KEY (notification_channel);


--
-- Name: feature_flags feature_flags_pkey; Type: CONSTRAINT; Schema: configuration; Owner: -
--

ALTER TABLE ONLY configuration.feature_flags
    ADD CONSTRAINT feature_flags_pkey PRIMARY KEY (feature_flag_id);


--
-- Name: feature_settings feature_settings_pkey; Type: CONSTRAINT; Schema: configuration; Owner: -
--

ALTER TABLE ONLY configuration.feature_settings
    ADD CONSTRAINT feature_settings_pkey PRIMARY KEY (feature_id, name);


--
-- Name: features features_name_key; Type: CONSTRAINT; Schema: configuration; Owner: -
--

ALTER TABLE ONLY configuration.features
    ADD CONSTRAINT features_name_key UNIQUE (name);


--
-- Name: features features_pkey; Type: CONSTRAINT; Schema: configuration; Owner: -
--

ALTER TABLE ONLY configuration.features
    ADD CONSTRAINT features_pkey PRIMARY KEY (feature_id);


--
-- Name: filtered_words filtered_words_pkey; Type: CONSTRAINT; Schema: configuration; Owner: -
--

ALTER TABLE ONLY configuration.filtered_words
    ADD CONSTRAINT filtered_words_pkey PRIMARY KEY (id);


--
-- Name: filtered_words filtered_words_word_key; Type: CONSTRAINT; Schema: configuration; Owner: -
--

ALTER TABLE ONLY configuration.filtered_words
    ADD CONSTRAINT filtered_words_word_key UNIQUE (word);


--
-- Name: global global_pkey; Type: CONSTRAINT; Schema: configuration; Owner: -
--

ALTER TABLE ONLY configuration.global
    ADD CONSTRAINT global_pkey PRIMARY KEY (name);


--
-- Name: platforms platforms_name_key; Type: CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.platforms
    ADD CONSTRAINT platforms_name_key UNIQUE (name);


--
-- Name: platforms platforms_pkey; Type: CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.platforms
    ADD CONSTRAINT platforms_pkey PRIMARY KEY (platform_id);


--
-- Name: verification_chat_messages verification_chat_messages_message_id_key; Type: CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.verification_chat_messages
    ADD CONSTRAINT verification_chat_messages_message_id_key UNIQUE (message_id);


--
-- Name: verification_chat_messages verification_chat_messages_pkey; Type: CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.verification_chat_messages
    ADD CONSTRAINT verification_chat_messages_pkey PRIMARY KEY (verification_id);


--
-- Name: verification_favourites verification_favourites_favourite_id_key; Type: CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.verification_favourites
    ADD CONSTRAINT verification_favourites_favourite_id_key UNIQUE (favourite_id);


--
-- Name: verification_favourites verification_favourites_pkey; Type: CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.verification_favourites
    ADD CONSTRAINT verification_favourites_pkey PRIMARY KEY (verification_id);


--
-- Name: verification_registrations verification_registrations_pkey; Type: CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.verification_registrations
    ADD CONSTRAINT verification_registrations_pkey PRIMARY KEY (verification_id);


--
-- Name: verification_statuses verification_statuses_pkey; Type: CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.verification_statuses
    ADD CONSTRAINT verification_statuses_pkey PRIMARY KEY (verification_id);


--
-- Name: verification_statuses verification_statuses_status_id_key; Type: CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.verification_statuses
    ADD CONSTRAINT verification_statuses_status_id_key UNIQUE (status_id);


--
-- Name: verification_users verification_users_pkey; Type: CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.verification_users
    ADD CONSTRAINT verification_users_pkey PRIMARY KEY (verification_id);


--
-- Name: verifications verifications_pkey; Type: CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.verifications
    ADD CONSTRAINT verifications_pkey PRIMARY KEY (verification_id);


--
-- Name: account_feeds account_feeds_account_id_feed_id_key; Type: CONSTRAINT; Schema: feeds; Owner: -
--

ALTER TABLE ONLY feeds.account_feeds
    ADD CONSTRAINT account_feeds_account_id_feed_id_key UNIQUE (account_id, feed_id);


--
-- Name: account_feeds account_feeds_account_id_position_key; Type: CONSTRAINT; Schema: feeds; Owner: -
--

ALTER TABLE ONLY feeds.account_feeds
    ADD CONSTRAINT account_feeds_account_id_position_key UNIQUE (account_id, "position");


--
-- Name: account_feeds account_feeds_pkey; Type: CONSTRAINT; Schema: feeds; Owner: -
--

ALTER TABLE ONLY feeds.account_feeds
    ADD CONSTRAINT account_feeds_pkey PRIMARY KEY (account_feed_id);


--
-- Name: feed_accounts feed_accounts_pkey; Type: CONSTRAINT; Schema: feeds; Owner: -
--

ALTER TABLE ONLY feeds.feed_accounts
    ADD CONSTRAINT feed_accounts_pkey PRIMARY KEY (feed_id, account_id);


--
-- Name: feeds feeds_created_by_account_id_name_key; Type: CONSTRAINT; Schema: feeds; Owner: -
--

ALTER TABLE ONLY feeds.feeds
    ADD CONSTRAINT feeds_created_by_account_id_name_key UNIQUE (created_by_account_id, name);


--
-- Name: feeds feeds_pkey; Type: CONSTRAINT; Schema: feeds; Owner: -
--

ALTER TABLE ONLY feeds.feeds
    ADD CONSTRAINT feeds_pkey PRIMARY KEY (feed_id);


--
-- Name: cities cities_name_region_id_key; Type: CONSTRAINT; Schema: geography; Owner: -
--

ALTER TABLE ONLY geography.cities
    ADD CONSTRAINT cities_name_region_id_key UNIQUE (name, region_id);


--
-- Name: cities cities_pkey; Type: CONSTRAINT; Schema: geography; Owner: -
--

ALTER TABLE ONLY geography.cities
    ADD CONSTRAINT cities_pkey PRIMARY KEY (city_id);


--
-- Name: countries countries_code_key; Type: CONSTRAINT; Schema: geography; Owner: -
--

ALTER TABLE ONLY geography.countries
    ADD CONSTRAINT countries_code_key UNIQUE (code);


--
-- Name: countries countries_name_key; Type: CONSTRAINT; Schema: geography; Owner: -
--

ALTER TABLE ONLY geography.countries
    ADD CONSTRAINT countries_name_key UNIQUE (name);


--
-- Name: countries countries_pkey; Type: CONSTRAINT; Schema: geography; Owner: -
--

ALTER TABLE ONLY geography.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (country_id);


--
-- Name: regions regions_code_country_id_key; Type: CONSTRAINT; Schema: geography; Owner: -
--

ALTER TABLE ONLY geography.regions
    ADD CONSTRAINT regions_code_country_id_key UNIQUE (code, country_id);


--
-- Name: regions regions_name_country_id_key; Type: CONSTRAINT; Schema: geography; Owner: -
--

ALTER TABLE ONLY geography.regions
    ADD CONSTRAINT regions_name_country_id_key UNIQUE (name, country_id);


--
-- Name: regions regions_pkey; Type: CONSTRAINT; Schema: geography; Owner: -
--

ALTER TABLE ONLY geography.regions
    ADD CONSTRAINT regions_pkey PRIMARY KEY (region_id);


--
-- Name: account_deletions account_deletions_pkey; Type: CONSTRAINT; Schema: logs; Owner: -
--

ALTER TABLE ONLY logs.account_deletions
    ADD CONSTRAINT account_deletions_pkey PRIMARY KEY (account_id);


--
-- Name: marketing_analytics marketing_analytics_pkey; Type: CONSTRAINT; Schema: notifications; Owner: -
--

ALTER TABLE ONLY notifications.marketing_analytics
    ADD CONSTRAINT marketing_analytics_pkey PRIMARY KEY (marketing_id, oauth_access_token_id);


--
-- Name: marketing marketing_pkey; Type: CONSTRAINT; Schema: notifications; Owner: -
--

ALTER TABLE ONLY notifications.marketing
    ADD CONSTRAINT marketing_pkey PRIMARY KEY (marketing_id);


--
-- Name: integrity_credentials integrity_credentials_pkey; Type: CONSTRAINT; Schema: oauth_access_tokens; Owner: -
--

ALTER TABLE ONLY oauth_access_tokens.integrity_credentials
    ADD CONSTRAINT integrity_credentials_pkey PRIMARY KEY (oauth_access_token_id, verification_id);


--
-- Name: webauthn_credentials webauthn_credentials_pkey; Type: CONSTRAINT; Schema: oauth_access_tokens; Owner: -
--

ALTER TABLE ONLY oauth_access_tokens.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_pkey PRIMARY KEY (oauth_access_token_id, webauthn_credential_id);


--
-- Name: options options_pkey; Type: CONSTRAINT; Schema: polls; Owner: -
--

ALTER TABLE ONLY polls.options
    ADD CONSTRAINT options_pkey PRIMARY KEY (poll_id, option_number);


--
-- Name: polls polls_pkey; Type: CONSTRAINT; Schema: polls; Owner: -
--

ALTER TABLE ONLY polls.polls
    ADD CONSTRAINT polls_pkey PRIMARY KEY (poll_id);


--
-- Name: status_polls status_polls_pkey; Type: CONSTRAINT; Schema: polls; Owner: -
--

ALTER TABLE ONLY polls.status_polls
    ADD CONSTRAINT status_polls_pkey PRIMARY KEY (status_id);


--
-- Name: status_polls status_polls_poll_id_key; Type: CONSTRAINT; Schema: polls; Owner: -
--

ALTER TABLE ONLY polls.status_polls
    ADD CONSTRAINT status_polls_poll_id_key UNIQUE (poll_id);


--
-- Name: votes votes_pkey; Type: CONSTRAINT; Schema: polls; Owner: -
--

ALTER TABLE ONLY polls.votes
    ADD CONSTRAINT votes_pkey PRIMARY KEY (poll_id, option_number, account_id);


--
-- Name: account_aliases account_aliases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_aliases
    ADD CONSTRAINT account_aliases_pkey PRIMARY KEY (id);


--
-- Name: account_conversations account_conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_conversations
    ADD CONSTRAINT account_conversations_pkey PRIMARY KEY (id);


--
-- Name: account_deletion_requests account_deletion_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_deletion_requests
    ADD CONSTRAINT account_deletion_requests_pkey PRIMARY KEY (id);


--
-- Name: account_identity_proofs account_identity_proofs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_identity_proofs
    ADD CONSTRAINT account_identity_proofs_pkey PRIMARY KEY (id);


--
-- Name: account_migrations account_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_migrations
    ADD CONSTRAINT account_migrations_pkey PRIMARY KEY (id);


--
-- Name: account_moderation_notes account_moderation_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_moderation_notes
    ADD CONSTRAINT account_moderation_notes_pkey PRIMARY KEY (id);


--
-- Name: account_notes account_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_notes
    ADD CONSTRAINT account_notes_pkey PRIMARY KEY (id);


--
-- Name: account_pins account_pins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_pins
    ADD CONSTRAINT account_pins_pkey PRIMARY KEY (id);


--
-- Name: account_stats account_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_stats
    ADD CONSTRAINT account_stats_pkey PRIMARY KEY (id);


--
-- Name: account_warning_presets account_warning_presets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_warning_presets
    ADD CONSTRAINT account_warning_presets_pkey PRIMARY KEY (id);


--
-- Name: account_warnings account_warnings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_warnings
    ADD CONSTRAINT account_warnings_pkey PRIMARY KEY (id);


--
-- Name: accounts_tags accounts_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts_tags
    ADD CONSTRAINT accounts_tags_pkey PRIMARY KEY (account_id, tag_id);


--
-- Name: ad_attributions ad_attributions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ad_attributions
    ADD CONSTRAINT ad_attributions_pkey PRIMARY KEY (ad_attribution_id);


--
-- Name: admin_action_logs admin_action_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_action_logs
    ADD CONSTRAINT admin_action_logs_pkey PRIMARY KEY (id);


--
-- Name: ads ads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ads
    ADD CONSTRAINT ads_pkey PRIMARY KEY (id);


--
-- Name: ads ads_status_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ads
    ADD CONSTRAINT ads_status_id_key UNIQUE (status_id);


--
-- Name: announcement_mutes announcement_mutes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcement_mutes
    ADD CONSTRAINT announcement_mutes_pkey PRIMARY KEY (id);


--
-- Name: announcement_reactions announcement_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcement_reactions
    ADD CONSTRAINT announcement_reactions_pkey PRIMARY KEY (id);


--
-- Name: announcements announcements_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcements
    ADD CONSTRAINT announcements_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: backups backups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.backups
    ADD CONSTRAINT backups_pkey PRIMARY KEY (id);


--
-- Name: blocked_links blocked_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocked_links
    ADD CONSTRAINT blocked_links_pkey PRIMARY KEY (url_pattern);


--
-- Name: bookmarks bookmarks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT bookmarks_pkey PRIMARY KEY (id);


--
-- Name: canonical_email_blocks canonical_email_blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.canonical_email_blocks
    ADD CONSTRAINT canonical_email_blocks_pkey PRIMARY KEY (id);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- Name: csv_exports csv_exports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.csv_exports
    ADD CONSTRAINT csv_exports_pkey PRIMARY KEY (id);


--
-- Name: custom_emoji_categories custom_emoji_categories_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_emoji_categories
    ADD CONSTRAINT custom_emoji_categories_pkey PRIMARY KEY (id);


--
-- Name: custom_emojis custom_emojis_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_emojis
    ADD CONSTRAINT custom_emojis_pkey PRIMARY KEY (id);


--
-- Name: custom_filters custom_filters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_filters
    ADD CONSTRAINT custom_filters_pkey PRIMARY KEY (id);


--
-- Name: devices devices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT devices_pkey PRIMARY KEY (id);


--
-- Name: domain_allows domain_allows_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.domain_allows
    ADD CONSTRAINT domain_allows_pkey PRIMARY KEY (id);


--
-- Name: email_domain_blocks email_domain_blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_domain_blocks
    ADD CONSTRAINT email_domain_blocks_pkey PRIMARY KEY (id);


--
-- Name: encrypted_messages encrypted_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encrypted_messages
    ADD CONSTRAINT encrypted_messages_pkey PRIMARY KEY (id);


--
-- Name: external_ads external_ads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.external_ads
    ADD CONSTRAINT external_ads_pkey PRIMARY KEY (external_ad_id);


--
-- Name: featured_tags featured_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.featured_tags
    ADD CONSTRAINT featured_tags_pkey PRIMARY KEY (id);


--
-- Name: follow_deletes follow_deletes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follow_deletes
    ADD CONSTRAINT follow_deletes_pkey PRIMARY KEY (id);


--
-- Name: follow_recommendation_suppressions follow_recommendation_suppressions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follow_recommendation_suppressions
    ADD CONSTRAINT follow_recommendation_suppressions_pkey PRIMARY KEY (id);


--
-- Name: group_account_blocks group_account_blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_account_blocks
    ADD CONSTRAINT group_account_blocks_pkey PRIMARY KEY (id);


--
-- Name: group_deletion_requests group_deletion_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_deletion_requests
    ADD CONSTRAINT group_deletion_requests_pkey PRIMARY KEY (id);


--
-- Name: group_membership_requests group_membership_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_membership_requests
    ADD CONSTRAINT group_membership_requests_pkey PRIMARY KEY (id);


--
-- Name: group_memberships group_memberships_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_memberships
    ADD CONSTRAINT group_memberships_pkey PRIMARY KEY (id);


--
-- Name: group_mutes group_mutes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_mutes
    ADD CONSTRAINT group_mutes_pkey PRIMARY KEY (account_id, group_id);


--
-- Name: group_stats group_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_stats
    ADD CONSTRAINT group_stats_pkey PRIMARY KEY (id);


--
-- Name: group_suggestion_deletes group_suggestion_deletes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_suggestion_deletes
    ADD CONSTRAINT group_suggestion_deletes_pkey PRIMARY KEY (account_id, group_id);


--
-- Name: group_suggestions group_suggestions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_suggestions
    ADD CONSTRAINT group_suggestions_pkey PRIMARY KEY (id);


--
-- Name: group_tags group_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_tags
    ADD CONSTRAINT group_tags_pkey PRIMARY KEY (group_id, tag_id);


--
-- Name: groups groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_pkey PRIMARY KEY (id);


--
-- Name: account_domain_blocks index_account_domain_blocks_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_domain_blocks
    ADD CONSTRAINT index_account_domain_blocks_on_id PRIMARY KEY (id);


--
-- Name: accounts index_accounts_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT index_accounts_on_id PRIMARY KEY (id);


--
-- Name: blocks index_blocks_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocks
    ADD CONSTRAINT index_blocks_on_id PRIMARY KEY (id);


--
-- Name: conversation_mutes index_conversation_mutes_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_mutes
    ADD CONSTRAINT index_conversation_mutes_on_id PRIMARY KEY (id);


--
-- Name: domain_blocks index_domain_blocks_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.domain_blocks
    ADD CONSTRAINT index_domain_blocks_on_id PRIMARY KEY (id);


--
-- Name: favourites index_favourites_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favourites
    ADD CONSTRAINT index_favourites_on_id PRIMARY KEY (id);


--
-- Name: follow_requests index_follow_requests_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follow_requests
    ADD CONSTRAINT index_follow_requests_on_id PRIMARY KEY (id);


--
-- Name: follows index_follows_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follows
    ADD CONSTRAINT index_follows_on_id PRIMARY KEY (id);


--
-- Name: identities index_identities_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identities
    ADD CONSTRAINT index_identities_on_id PRIMARY KEY (id);


--
-- Name: imports index_imports_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imports
    ADD CONSTRAINT index_imports_on_id PRIMARY KEY (id);


--
-- Name: media_attachments index_media_attachments_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_attachments
    ADD CONSTRAINT index_media_attachments_on_id PRIMARY KEY (id);


--
-- Name: mentions index_mentions_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mentions
    ADD CONSTRAINT index_mentions_on_id PRIMARY KEY (id);


--
-- Name: mutes index_mutes_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mutes
    ADD CONSTRAINT index_mutes_on_id PRIMARY KEY (id);


--
-- Name: oauth_access_grants index_oauth_access_grants_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT index_oauth_access_grants_on_id PRIMARY KEY (id);


--
-- Name: oauth_access_tokens index_oauth_access_tokens_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT index_oauth_access_tokens_on_id PRIMARY KEY (id);


--
-- Name: oauth_applications index_oauth_applications_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_applications
    ADD CONSTRAINT index_oauth_applications_on_id PRIMARY KEY (id);


--
-- Name: reports index_reports_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT index_reports_on_id PRIMARY KEY (id);


--
-- Name: settings index_settings_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT index_settings_on_id PRIMARY KEY (id);


--
-- Name: tags index_tags_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT index_tags_on_id PRIMARY KEY (id);


--
-- Name: users index_users_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT index_users_on_id PRIMARY KEY (id);


--
-- Name: web_settings index_web_settings_on_id; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_settings
    ADD CONSTRAINT index_web_settings_on_id PRIMARY KEY (id);


--
-- Name: invites invites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invites
    ADD CONSTRAINT invites_pkey PRIMARY KEY (id);


--
-- Name: ip_blocks ip_blocks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ip_blocks
    ADD CONSTRAINT ip_blocks_pkey PRIMARY KEY (id);


--
-- Name: links links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.links
    ADD CONSTRAINT links_pkey PRIMARY KEY (id);


--
-- Name: links_statuses links_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.links_statuses
    ADD CONSTRAINT links_statuses_pkey PRIMARY KEY (status_id, link_id);


--
-- Name: links links_url_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.links
    ADD CONSTRAINT links_url_key UNIQUE (url);


--
-- Name: list_accounts list_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.list_accounts
    ADD CONSTRAINT list_accounts_pkey PRIMARY KEY (id);


--
-- Name: lists lists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lists
    ADD CONSTRAINT lists_pkey PRIMARY KEY (id);


--
-- Name: logs logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id);


--
-- Name: markers markers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.markers
    ADD CONSTRAINT markers_pkey PRIMARY KEY (id);


--
-- Name: moderation_records moderation_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.moderation_records
    ADD CONSTRAINT moderation_records_pkey PRIMARY KEY (id);


--
-- Name: one_time_challenges one_time_challenges_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.one_time_challenges
    ADD CONSTRAINT one_time_challenges_pkey PRIMARY KEY (id);


--
-- Name: one_time_keys one_time_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.one_time_keys
    ADD CONSTRAINT one_time_keys_pkey PRIMARY KEY (id);


--
-- Name: policies policies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.policies
    ADD CONSTRAINT policies_pkey PRIMARY KEY (id);


--
-- Name: preview_cards preview_cards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preview_cards
    ADD CONSTRAINT preview_cards_pkey PRIMARY KEY (id);


--
-- Name: preview_cards_statuses preview_cards_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.preview_cards_statuses
    ADD CONSTRAINT preview_cards_statuses_pkey PRIMARY KEY (preview_card_id, status_id);


--
-- Name: relays relays_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.relays
    ADD CONSTRAINT relays_pkey PRIMARY KEY (id);


--
-- Name: report_notes report_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_notes
    ADD CONSTRAINT report_notes_pkey PRIMARY KEY (id);


--
-- Name: rules rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rules
    ADD CONSTRAINT rules_pkey PRIMARY KEY (id);


--
-- Name: scheduled_statuses scheduled_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduled_statuses
    ADD CONSTRAINT scheduled_statuses_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: session_activations session_activations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_activations
    ADD CONSTRAINT session_activations_pkey PRIMARY KEY (id);


--
-- Name: site_uploads site_uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.site_uploads
    ADD CONSTRAINT site_uploads_pkey PRIMARY KEY (id);


--
-- Name: status_pins status_pins_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_pins
    ADD CONSTRAINT status_pins_pkey PRIMARY KEY (id);


--
-- Name: status_stats status_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_stats
    ADD CONSTRAINT status_stats_pkey PRIMARY KEY (id);


--
-- Name: statuses statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statuses
    ADD CONSTRAINT statuses_pkey PRIMARY KEY (id);


--
-- Name: statuses_tags statuses_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statuses_tags
    ADD CONSTRAINT statuses_tags_pkey PRIMARY KEY (status_id, tag_id);


--
-- Name: system_keys system_keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_keys
    ADD CONSTRAINT system_keys_pkey PRIMARY KEY (id);


--
-- Name: tombstones tombstones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tombstones
    ADD CONSTRAINT tombstones_pkey PRIMARY KEY (id);


--
-- Name: unavailable_domains unavailable_domains_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.unavailable_domains
    ADD CONSTRAINT unavailable_domains_pkey PRIMARY KEY (id);


--
-- Name: user_invite_requests user_invite_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_invite_requests
    ADD CONSTRAINT user_invite_requests_pkey PRIMARY KEY (id);


--
-- Name: web_push_subscriptions web_push_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_push_subscriptions
    ADD CONSTRAINT web_push_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: webauthn_credentials webauthn_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_pkey PRIMARY KEY (id);


--
-- Name: account_suppressions account_suppressions_pkey; Type: CONSTRAINT; Schema: recommendations; Owner: -
--

ALTER TABLE ONLY recommendations.account_suppressions
    ADD CONSTRAINT account_suppressions_pkey PRIMARY KEY (account_id, target_account_id);


--
-- Name: follows follows_pkey; Type: CONSTRAINT; Schema: recommendations; Owner: -
--

ALTER TABLE ONLY recommendations.follows
    ADD CONSTRAINT follows_pkey PRIMARY KEY (account_id);


--
-- Name: group_suppressions group_suppressions_pkey; Type: CONSTRAINT; Schema: recommendations; Owner: -
--

ALTER TABLE ONLY recommendations.group_suppressions
    ADD CONSTRAINT group_suppressions_pkey PRIMARY KEY (account_id, group_id);


--
-- Name: statuses statuses_pkey; Type: CONSTRAINT; Schema: recommendations; Owner: -
--

ALTER TABLE ONLY recommendations.statuses
    ADD CONSTRAINT statuses_pkey PRIMARY KEY (account_id);


--
-- Name: emojis emojis_emoji_key; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.emojis
    ADD CONSTRAINT emojis_emoji_key UNIQUE (emoji);


--
-- Name: emojis emojis_pkey; Type: CONSTRAINT; Schema: reference; Owner: -
--

ALTER TABLE ONLY reference.emojis
    ADD CONSTRAINT emojis_pkey PRIMARY KEY (emoji_id);


--
-- Name: one_time_challenges one_time_challenges_one_time_challenge_id_key; Type: CONSTRAINT; Schema: registrations; Owner: -
--

ALTER TABLE ONLY registrations.one_time_challenges
    ADD CONSTRAINT one_time_challenges_one_time_challenge_id_key UNIQUE (one_time_challenge_id);


--
-- Name: one_time_challenges one_time_challenges_pkey; Type: CONSTRAINT; Schema: registrations; Owner: -
--

ALTER TABLE ONLY registrations.one_time_challenges
    ADD CONSTRAINT one_time_challenges_pkey PRIMARY KEY (registration_id);


--
-- Name: registrations registrations_pkey; Type: CONSTRAINT; Schema: registrations; Owner: -
--

ALTER TABLE ONLY registrations.registrations
    ADD CONSTRAINT registrations_pkey PRIMARY KEY (registration_id);


--
-- Name: webauthn_credentials webauthn_credentials_pkey; Type: CONSTRAINT; Schema: registrations; Owner: -
--

ALTER TABLE ONLY registrations.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_pkey PRIMARY KEY (registration_id);


--
-- Name: account_followers account_followers_pkey; Type: CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.account_followers
    ADD CONSTRAINT account_followers_pkey PRIMARY KEY (account_id);


--
-- Name: account_following account_following_pkey; Type: CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.account_following
    ADD CONSTRAINT account_following_pkey PRIMARY KEY (account_id);


--
-- Name: account_statuses account_statuses_pkey; Type: CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.account_statuses
    ADD CONSTRAINT account_statuses_pkey PRIMARY KEY (account_id);


--
-- Name: daily_active_user_counts daily_active_users_pkey; Type: CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.daily_active_user_counts
    ADD CONSTRAINT daily_active_users_pkey PRIMARY KEY (date);


--
-- Name: daily_active_users daily_active_users_pkey1; Type: CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.daily_active_users
    ADD CONSTRAINT daily_active_users_pkey1 PRIMARY KEY (date, user_id);


--
-- Name: poll_options poll_options_pkey; Type: CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.poll_options
    ADD CONSTRAINT poll_options_pkey PRIMARY KEY (poll_id, option_number);


--
-- Name: polls polls_pkey; Type: CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.polls
    ADD CONSTRAINT polls_pkey PRIMARY KEY (poll_id);


--
-- Name: reply_status_controversial_scores reply_status_controversial_scores_pkey; Type: CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.reply_status_controversial_scores
    ADD CONSTRAINT reply_status_controversial_scores_pkey PRIMARY KEY (status_id);


--
-- Name: reply_status_trending_scores reply_status_trending_scores_pkey; Type: CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.reply_status_trending_scores
    ADD CONSTRAINT reply_status_trending_scores_pkey PRIMARY KEY (status_id);


--
-- Name: status_engagement status_engagement_pkey; Type: CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.status_engagement
    ADD CONSTRAINT status_engagement_pkey PRIMARY KEY (status_id);


--
-- Name: status_favourites status_favourites_pkey; Type: CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.status_favourites
    ADD CONSTRAINT status_favourites_pkey PRIMARY KEY (status_id);


--
-- Name: status_reblogs status_reblogs_pkey; Type: CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.status_reblogs
    ADD CONSTRAINT status_reblogs_pkey PRIMARY KEY (status_id);


--
-- Name: status_replies status_replies_pkey; Type: CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.status_replies
    ADD CONSTRAINT status_replies_pkey PRIMARY KEY (status_id);


--
-- Name: status_view_counts status_view_counts_pkey; Type: CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.status_view_counts
    ADD CONSTRAINT status_view_counts_pkey PRIMARY KEY (status_id);


--
-- Name: analysis analysis_pkey; Type: CONSTRAINT; Schema: statuses; Owner: -
--

ALTER TABLE ONLY statuses.analysis
    ADD CONSTRAINT analysis_pkey PRIMARY KEY (status_id);


--
-- Name: moderation_results moderation_results_pkey; Type: CONSTRAINT; Schema: statuses; Owner: -
--

ALTER TABLE ONLY statuses.moderation_results
    ADD CONSTRAINT moderation_results_pkey PRIMARY KEY (status_id, created_at);


--
-- Name: excluded_groups excluded_groups_pkey; Type: CONSTRAINT; Schema: trending_groups; Owner: -
--

ALTER TABLE ONLY trending_groups.excluded_groups
    ADD CONSTRAINT excluded_groups_pkey PRIMARY KEY (group_id);


--
-- Name: excluded_statuses excluded_statuses_pkey; Type: CONSTRAINT; Schema: trending_statuses; Owner: -
--

ALTER TABLE ONLY trending_statuses.excluded_statuses
    ADD CONSTRAINT excluded_statuses_pkey PRIMARY KEY (status_id);


--
-- Name: accounts accounts_account_uuid_key; Type: CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.accounts
    ADD CONSTRAINT accounts_account_uuid_key UNIQUE (account_uuid);


--
-- Name: accounts accounts_pprofile_id_key; Type: CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.accounts
    ADD CONSTRAINT accounts_p_profile_id_key UNIQUE (p_profile_id);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (account_id);


--
-- Name: channel_accounts channel_accounts_pkey; Type: CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.channel_accounts
    ADD CONSTRAINT channel_accounts_pkey PRIMARY KEY (channel_id, account_id);


--
-- Name: channels channels_pkey; Type: CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.channels
    ADD CONSTRAINT channels_pkey PRIMARY KEY (channel_id);


--
-- Name: deleted_accounts deleted_accounts_pkey; Type: CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.deleted_accounts
    ADD CONSTRAINT deleted_accounts_pkey PRIMARY KEY (p_profile_id);


--
-- Name: device_sessions device_sessions_pkey; Type: CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.device_sessions
    ADD CONSTRAINT device_sessions_pkey PRIMARY KEY (oauth_access_token_id);


--
-- Name: device_sessions device_sessions_tv_session_id_key; Type: CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.device_sessions
    ADD CONSTRAINT device_sessions_tv_session_id_key UNIQUE (tv_session_id);


--
-- Name: program_statuses program_statuses_pkey; Type: CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.program_statuses
    ADD CONSTRAINT program_statuses_pkey PRIMARY KEY (channel_id, start_time, status_id);


--
-- Name: programs programs_pkey; Type: CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.programs
    ADD CONSTRAINT programs_pkey PRIMARY KEY (channel_id, start_time);


--
-- Name: programs_temporary programs_temporary_pkey; Type: CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.programs_temporary
    ADD CONSTRAINT programs_temporary_pkey PRIMARY KEY (channel_id, start_time);


--
-- Name: reminders reminders_pkey; Type: CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.reminders
    ADD CONSTRAINT reminders_pkey PRIMARY KEY (account_id, channel_id, start_time);


--
-- Name: statuses statuses_pkey; Type: CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.statuses
    ADD CONSTRAINT statuses_pkey PRIMARY KEY (status_id);


--
-- Name: base_emails base_emails_email_key; Type: CONSTRAINT; Schema: users; Owner: -
--

ALTER TABLE ONLY users.base_emails
    ADD CONSTRAINT base_emails_email_key UNIQUE (email);


--
-- Name: base_emails base_emails_pkey; Type: CONSTRAINT; Schema: users; Owner: -
--

ALTER TABLE ONLY users.base_emails
    ADD CONSTRAINT base_emails_pkey PRIMARY KEY (user_id);


--
-- Name: current_information current_information_pkey; Type: CONSTRAINT; Schema: users; Owner: -
--

ALTER TABLE ONLY users.current_information
    ADD CONSTRAINT current_information_pkey PRIMARY KEY (user_id);


--
-- Name: one_time_challenges one_time_challenges_pkey; Type: CONSTRAINT; Schema: users; Owner: -
--

ALTER TABLE ONLY users.one_time_challenges
    ADD CONSTRAINT one_time_challenges_pkey PRIMARY KEY (user_id, one_time_challenge_id);


--
-- Name: password_histories password_histories_pkey; Type: CONSTRAINT; Schema: users; Owner: -
--

ALTER TABLE ONLY users.password_histories
    ADD CONSTRAINT password_histories_pkey PRIMARY KEY (user_id, created_at);


--
-- Name: sms_reverification_required sms_reverification_required_pkey; Type: CONSTRAINT; Schema: users; Owner: -
--

ALTER TABLE ONLY users.sms_reverification_required
    ADD CONSTRAINT sms_reverification_required_pkey PRIMARY KEY (user_id);


--
-- Name: group_status_tag_uses_group_id_tag_id_idx; Type: INDEX; Schema: cache; Owner: -
--

CREATE UNIQUE INDEX group_status_tag_uses_group_id_tag_id_idx ON cache.group_tag_uses USING btree (group_id, tag_id);


--
-- Name: group_status_tags_group_id_created_at_idx; Type: INDEX; Schema: cache; Owner: -
--

CREATE INDEX group_status_tags_group_id_created_at_idx ON cache.group_status_tags USING btree (group_id, created_at);


--
-- Name: group_status_tags_group_id_tag_id_created_at_idx; Type: INDEX; Schema: cache; Owner: -
--

CREATE INDEX group_status_tags_group_id_tag_id_created_at_idx ON cache.group_status_tags USING btree (group_id, tag_id, created_at);


--
-- Name: status_tags_created_at_idx; Type: INDEX; Schema: cache; Owner: -
--

CREATE INDEX status_tags_created_at_idx ON cache.status_tags USING btree (created_at);


--
-- Name: status_tags_tag_id_created_at_idx; Type: INDEX; Schema: cache; Owner: -
--

CREATE INDEX status_tags_tag_id_created_at_idx ON cache.status_tags USING btree (tag_id, created_at);


--
-- Name: tag_uses_tag_id_idx; Type: INDEX; Schema: cache; Owner: -
--

CREATE UNIQUE INDEX tag_uses_tag_id_idx ON cache.tag_uses USING btree (tag_id);


--
-- Name: chat_silences_account_id_event_id_idx; Type: INDEX; Schema: chat_events; Owner: -
--

CREATE INDEX chat_silences_account_id_event_id_idx ON chat_events.chat_silences USING btree (account_id, event_id);


--
-- Name: chat_unsilences_account_id_event_id_idx; Type: INDEX; Schema: chat_events; Owner: -
--

CREATE INDEX chat_unsilences_account_id_event_id_idx ON chat_events.chat_unsilences USING btree (account_id, event_id);


--
-- Name: index_on_events_chat_id_event_type; Type: INDEX; Schema: chat_events; Owner: -
--

CREATE INDEX index_on_events_chat_id_event_type ON chat_events.events USING btree (chat_id, event_type);


--
-- Name: index_on_member_avatar_changes_account_id; Type: INDEX; Schema: chat_events; Owner: -
--

CREATE INDEX index_on_member_avatar_changes_account_id ON chat_events.member_avatar_changes USING btree (account_id);


--
-- Name: index_on_member_latest_read_message_changes_account_id; Type: INDEX; Schema: chat_events; Owner: -
--

CREATE INDEX index_on_member_latest_read_message_changes_account_id ON chat_events.member_latest_read_message_changes USING btree (account_id);


--
-- Name: index_on_message_reactions_changes_message_id; Type: INDEX; Schema: chat_events; Owner: -
--

CREATE INDEX index_on_message_reactions_changes_message_id ON chat_events.message_reactions_changes USING btree (message_id);


--
-- Name: message_creations_message_id_idx; Type: INDEX; Schema: chat_events; Owner: -
--

CREATE INDEX message_creations_message_id_idx ON chat_events.message_creations USING btree (message_id);


--
-- Name: message_hides_account_id_event_id_idx; Type: INDEX; Schema: chat_events; Owner: -
--

CREATE INDEX message_hides_account_id_event_id_idx ON chat_events.message_hides USING btree (account_id, event_id);


--
-- Name: subscriber_leaves_account_id_event_id_idx; Type: INDEX; Schema: chat_events; Owner: -
--

CREATE INDEX subscriber_leaves_account_id_event_id_idx ON chat_events.subscriber_leaves USING btree (account_id, event_id);


--
-- Name: subscriber_rejoins_account_id_event_id_idx; Type: INDEX; Schema: chat_events; Owner: -
--

CREATE INDEX subscriber_rejoins_account_id_event_id_idx ON chat_events.subscriber_rejoins USING btree (account_id, event_id);


--
-- Name: chats_owner_account_id_idx; Type: INDEX; Schema: chats; Owner: -
--

CREATE INDEX chats_owner_account_id_idx ON chats.chats USING btree (owner_account_id);


--
-- Name: deleted_messages_expired_idx; Type: INDEX; Schema: chats; Owner: -
--

CREATE INDEX deleted_messages_expired_idx ON chats.deleted_messages USING btree (((timezone('UTC'::text, created_at) + expiration)));


--
-- Name: index_on_deleted_chats_owner_account_id; Type: INDEX; Schema: chats; Owner: -
--

CREATE INDEX index_on_deleted_chats_owner_account_id ON chats.deleted_chats USING btree (owner_account_id);


--
-- Name: index_on_deleted_members_account_id; Type: INDEX; Schema: chats; Owner: -
--

CREATE INDEX index_on_deleted_members_account_id ON chats.deleted_members USING btree (account_id);


--
-- Name: index_on_deleted_messages_chat_id; Type: INDEX; Schema: chats; Owner: -
--

CREATE INDEX index_on_deleted_messages_chat_id ON chats.deleted_messages USING btree (chat_id);


--
-- Name: index_on_message_text_content; Type: INDEX; Schema: chats; Owner: -
--

CREATE INDEX index_on_message_text_content ON chats.message_text USING gin (to_tsvector('simple'::regconfig, content));


--
-- Name: member_lists_members_idx; Type: INDEX; Schema: chats; Owner: -
--

CREATE INDEX member_lists_members_idx ON chats.member_lists USING btree (members);


--
-- Name: members_account_id_idx; Type: INDEX; Schema: chats; Owner: -
--

CREATE INDEX members_account_id_idx ON chats.members USING btree (account_id);


--
-- Name: messages_chat_id_idx; Type: INDEX; Schema: chats; Owner: -
--

CREATE INDEX messages_chat_id_idx ON chats.messages USING btree (chat_id);


--
-- Name: messages_expired_idx; Type: INDEX; Schema: chats; Owner: -
--

CREATE INDEX messages_expired_idx ON chats.messages USING btree (((timezone('UTC'::text, created_at) + expiration)));


--
-- Name: verification_user_id_idx; Type: INDEX; Schema: devices; Owner: -
--

CREATE INDEX verification_user_id_idx ON devices.verification_users USING btree (user_id);


--
-- Name: verifications_registration_token_idx; Type: INDEX; Schema: devices; Owner: -
--

CREATE INDEX verifications_registration_token_idx ON devices.verifications USING btree (((details ->> 'registration_token'::text)));


--
-- Name: notifications_account_id_id_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_account_id_id_type_idx ON ONLY public.notifications USING btree (account_id, id DESC, type);


--
-- Name: part_1_account_id_id_type_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_1_account_id_id_type_idx ON notifications.part_1 USING btree (account_id, id DESC, type);


--
-- Name: notifications_activity_id_activity_type_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_activity_id_activity_type_idx ON ONLY public.notifications USING btree (activity_id, activity_type);


--
-- Name: part_1_activity_id_activity_type_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_1_activity_id_activity_type_idx ON notifications.part_1 USING btree (activity_id, activity_type);


--
-- Name: notifications_from_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_from_account_id_idx ON ONLY public.notifications USING btree (from_account_id);


--
-- Name: part_1_from_account_id_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_1_from_account_id_idx ON notifications.part_1 USING btree (from_account_id);


--
-- Name: notifications_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notifications_id_idx ON ONLY public.notifications USING btree (id);


--
-- Name: part_1_id_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_1_id_idx ON notifications.part_1 USING btree (id);


--
-- Name: part_2_account_id_id_type_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_2_account_id_id_type_idx ON notifications.part_2 USING btree (account_id, id DESC, type);


--
-- Name: part_2_activity_id_activity_type_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_2_activity_id_activity_type_idx ON notifications.part_2 USING btree (activity_id, activity_type);


--
-- Name: part_2_from_account_id_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_2_from_account_id_idx ON notifications.part_2 USING btree (from_account_id);


--
-- Name: part_2_id_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_2_id_idx ON notifications.part_2 USING btree (id);


--
-- Name: part_3_account_id_id_type_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_3_account_id_id_type_idx ON notifications.part_3 USING btree (account_id, id DESC, type);


--
-- Name: part_3_activity_id_activity_type_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_3_activity_id_activity_type_idx ON notifications.part_3 USING btree (activity_id, activity_type);


--
-- Name: part_3_from_account_id_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_3_from_account_id_idx ON notifications.part_3 USING btree (from_account_id);


--
-- Name: part_3_id_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_3_id_idx ON notifications.part_3 USING btree (id);


--
-- Name: part_4_account_id_id_type_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_4_account_id_id_type_idx ON notifications.part_4 USING btree (account_id, id DESC, type);


--
-- Name: part_4_activity_id_activity_type_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_4_activity_id_activity_type_idx ON notifications.part_4 USING btree (activity_id, activity_type);


--
-- Name: part_4_from_account_id_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_4_from_account_id_idx ON notifications.part_4 USING btree (from_account_id);


--
-- Name: part_4_id_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_4_id_idx ON notifications.part_4 USING btree (id);


--
-- Name: part_5_account_id_id_type_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_5_account_id_id_type_idx ON notifications.part_5 USING btree (account_id, id DESC, type);


--
-- Name: part_5_activity_id_activity_type_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_5_activity_id_activity_type_idx ON notifications.part_5 USING btree (activity_id, activity_type);


--
-- Name: part_5_from_account_id_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_5_from_account_id_idx ON notifications.part_5 USING btree (from_account_id);


--
-- Name: part_5_id_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_5_id_idx ON notifications.part_5 USING btree (id);


--
-- Name: part_6_account_id_id_type_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_6_account_id_id_type_idx ON notifications.part_6 USING btree (account_id, id DESC, type);


--
-- Name: part_6_activity_id_activity_type_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_6_activity_id_activity_type_idx ON notifications.part_6 USING btree (activity_id, activity_type);


--
-- Name: part_6_from_account_id_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_6_from_account_id_idx ON notifications.part_6 USING btree (from_account_id);


--
-- Name: part_6_id_idx; Type: INDEX; Schema: notifications; Owner: -
--

CREATE INDEX part_6_id_idx ON notifications.part_6 USING btree (id);


--
-- Name: favourites_account_id_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX favourites_account_id_id_idx ON public.favourites USING btree (account_id, id);


--
-- Name: favourites_created_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX favourites_created_at_index ON public.favourites USING btree (created_at);


--
-- Name: favourites_status_id_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX favourites_status_id_account_id_idx ON public.favourites USING btree (status_id, account_id);


--
-- Name: follows_account_id_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX follows_account_id_id_idx ON public.follows USING btree (account_id, id);


--
-- Name: follows_created_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX follows_created_at_index ON public.follows USING btree (created_at);


--
-- Name: group_tags_tag_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX group_tags_tag_id_idx ON public.group_tags USING btree (tag_id);


--
-- Name: index_account_aliases_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_aliases_on_account_id ON public.account_aliases USING btree (account_id);


--
-- Name: index_account_conversations_on_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_conversations_on_conversation_id ON public.account_conversations USING btree (conversation_id);


--
-- Name: index_account_deletion_requests_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_deletion_requests_on_account_id ON public.account_deletion_requests USING btree (account_id);


--
-- Name: index_account_domain_blocks_on_account_id_and_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_account_domain_blocks_on_account_id_and_domain ON public.account_domain_blocks USING btree (account_id, domain);


--
-- Name: index_account_migrations_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_migrations_on_account_id ON public.account_migrations USING btree (account_id);


--
-- Name: index_account_migrations_on_target_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_migrations_on_target_account_id ON public.account_migrations USING btree (target_account_id);


--
-- Name: index_account_moderation_notes_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_moderation_notes_on_account_id ON public.account_moderation_notes USING btree (account_id);


--
-- Name: index_account_moderation_notes_on_target_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_moderation_notes_on_target_account_id ON public.account_moderation_notes USING btree (target_account_id);


--
-- Name: index_account_notes_on_account_id_and_target_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_account_notes_on_account_id_and_target_account_id ON public.account_notes USING btree (account_id, target_account_id);


--
-- Name: index_account_notes_on_target_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_notes_on_target_account_id ON public.account_notes USING btree (target_account_id);


--
-- Name: index_account_pins_on_account_id_and_target_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_account_pins_on_account_id_and_target_account_id ON public.account_pins USING btree (account_id, target_account_id);


--
-- Name: index_account_pins_on_target_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_pins_on_target_account_id ON public.account_pins USING btree (target_account_id);


--
-- Name: index_account_proofs_on_account_and_provider_and_username; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_account_proofs_on_account_and_provider_and_username ON public.account_identity_proofs USING btree (account_id, provider, provider_username);


--
-- Name: index_account_stats_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_account_stats_on_account_id ON public.account_stats USING btree (account_id);


--
-- Name: index_account_summaries_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_account_summaries_on_account_id ON public.account_summaries USING btree (account_id);


--
-- Name: index_account_warnings_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_warnings_on_account_id ON public.account_warnings USING btree (account_id);


--
-- Name: index_account_warnings_on_target_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_account_warnings_on_target_account_id ON public.account_warnings USING btree (target_account_id);


--
-- Name: index_accounts_on_display_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_display_name ON public.accounts USING gin (display_name extension_pg_trgm.gin_trgm_ops);


--
-- Name: index_accounts_on_interactions_score; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_interactions_score ON public.accounts USING btree (interactions_score);


--
-- Name: index_accounts_on_moved_to_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_moved_to_account_id ON public.accounts USING btree (moved_to_account_id);


--
-- Name: index_accounts_on_uri; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_uri ON public.accounts USING btree (uri);


--
-- Name: index_accounts_on_url; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_url ON public.accounts USING btree (url);


--
-- Name: index_accounts_on_username; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_username ON public.accounts USING gin (username extension_pg_trgm.gin_trgm_ops);


--
-- Name: index_accounts_on_username_and_domain_lower; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accounts_on_username_and_domain_lower ON public.accounts USING btree (lower((username)::text), COALESCE(lower((domain)::text), ''::text));


--
-- Name: index_accounts_tags_on_tag_id_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accounts_tags_on_tag_id_and_account_id ON public.accounts_tags USING btree (tag_id, account_id);


--
-- Name: index_admin_action_logs_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_admin_action_logs_on_account_id ON public.admin_action_logs USING btree (account_id);


--
-- Name: index_admin_action_logs_on_target_type_and_target_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_admin_action_logs_on_target_type_and_target_id ON public.admin_action_logs USING btree (target_type, target_id);


--
-- Name: index_announcement_mutes_on_account_id_and_announcement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_announcement_mutes_on_account_id_and_announcement_id ON public.announcement_mutes USING btree (account_id, announcement_id);


--
-- Name: index_announcement_mutes_on_announcement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_announcement_mutes_on_announcement_id ON public.announcement_mutes USING btree (announcement_id);


--
-- Name: index_announcement_reactions_on_account_id_and_announcement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_announcement_reactions_on_account_id_and_announcement_id ON public.announcement_reactions USING btree (account_id, announcement_id, name);


--
-- Name: index_announcement_reactions_on_announcement_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_announcement_reactions_on_announcement_id ON public.announcement_reactions USING btree (announcement_id);


--
-- Name: index_announcement_reactions_on_custom_emoji_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_announcement_reactions_on_custom_emoji_id ON public.announcement_reactions USING btree (custom_emoji_id);


--
-- Name: index_blocks_on_account_id_and_target_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_blocks_on_account_id_and_target_account_id ON public.blocks USING btree (account_id, target_account_id);


--
-- Name: index_blocks_on_target_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_blocks_on_target_account_id ON public.blocks USING btree (target_account_id);


--
-- Name: index_bookmarks_on_account_id_and_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_bookmarks_on_account_id_and_status_id ON public.bookmarks USING btree (account_id, status_id);


--
-- Name: index_bookmarks_on_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bookmarks_on_status_id ON public.bookmarks USING btree (status_id);


--
-- Name: index_canonical_email_blocks_on_canonical_email_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_canonical_email_blocks_on_canonical_email_hash ON public.canonical_email_blocks USING btree (canonical_email_hash);


--
-- Name: index_canonical_email_blocks_on_reference_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_canonical_email_blocks_on_reference_account_id ON public.canonical_email_blocks USING btree (reference_account_id);


--
-- Name: index_conversation_mutes_on_account_id_and_conversation_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_conversation_mutes_on_account_id_and_conversation_id ON public.conversation_mutes USING btree (account_id, conversation_id);


--
-- Name: index_conversations_on_uri; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_conversations_on_uri ON public.conversations USING btree (uri);


--
-- Name: index_csv_exports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_csv_exports_on_user_id ON public.csv_exports USING btree (user_id);


--
-- Name: index_custom_emoji_categories_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_custom_emoji_categories_on_name ON public.custom_emoji_categories USING btree (name);


--
-- Name: index_custom_emojis_on_shortcode_and_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_custom_emojis_on_shortcode_and_domain ON public.custom_emojis USING btree (shortcode, domain);


--
-- Name: index_custom_filters_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_custom_filters_on_account_id ON public.custom_filters USING btree (account_id);


--
-- Name: index_devices_on_access_token_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_devices_on_access_token_id ON public.devices USING btree (access_token_id);


--
-- Name: index_devices_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_devices_on_account_id ON public.devices USING btree (account_id);


--
-- Name: index_domain_allows_on_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_domain_allows_on_domain ON public.domain_allows USING btree (domain);


--
-- Name: index_domain_blocks_on_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_domain_blocks_on_domain ON public.domain_blocks USING btree (domain);


--
-- Name: index_email_domain_blocks_on_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_email_domain_blocks_on_domain ON public.email_domain_blocks USING btree (domain);


--
-- Name: index_encrypted_messages_on_device_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_encrypted_messages_on_device_id ON public.encrypted_messages USING btree (device_id);


--
-- Name: index_encrypted_messages_on_from_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_encrypted_messages_on_from_account_id ON public.encrypted_messages USING btree (from_account_id);


--
-- Name: index_favourites_on_account_id_and_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favourites_on_account_id_and_id ON public.favourites USING btree (account_id, id);


--
-- Name: index_favourites_on_account_id_and_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_favourites_on_account_id_and_status_id ON public.favourites USING btree (account_id, status_id);


--
-- Name: index_favourites_on_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_favourites_on_status_id ON public.favourites USING btree (status_id);


--
-- Name: index_featured_tags_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_featured_tags_on_account_id ON public.featured_tags USING btree (account_id);


--
-- Name: index_featured_tags_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_featured_tags_on_tag_id ON public.featured_tags USING btree (tag_id);


--
-- Name: index_follow_deletes_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_follow_deletes_on_account_id ON public.follow_deletes USING btree (account_id);


--
-- Name: index_follow_recommendation_suppressions_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_follow_recommendation_suppressions_on_account_id ON public.follow_recommendation_suppressions USING btree (account_id);


--
-- Name: index_follow_recommendations_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_follow_recommendations_on_account_id ON public.follow_recommendations USING btree (account_id);


--
-- Name: index_follow_requests_on_account_id_and_target_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_follow_requests_on_account_id_and_target_account_id ON public.follow_requests USING btree (account_id, target_account_id);


--
-- Name: index_follows_on_account_id_and_target_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_follows_on_account_id_and_target_account_id ON public.follows USING btree (account_id, target_account_id);


--
-- Name: index_follows_on_target_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_follows_on_target_account_id ON public.follows USING btree (target_account_id);


--
-- Name: index_group_account_blocks_on_account_id_and_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_group_account_blocks_on_account_id_and_group_id ON public.group_account_blocks USING btree (account_id, group_id);


--
-- Name: index_group_account_blocks_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_account_blocks_on_group_id ON public.group_account_blocks USING btree (group_id);


--
-- Name: index_group_deletion_requests_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_deletion_requests_on_group_id ON public.group_deletion_requests USING btree (group_id);


--
-- Name: index_group_membership_requests_on_account_id_and_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_group_membership_requests_on_account_id_and_group_id ON public.group_membership_requests USING btree (account_id, group_id);


--
-- Name: index_group_membership_requests_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_membership_requests_on_group_id ON public.group_membership_requests USING btree (group_id);


--
-- Name: index_group_memberships_on_account_id_and_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_group_memberships_on_account_id_and_group_id ON public.group_memberships USING btree (account_id, group_id);


--
-- Name: index_group_memberships_on_group_id_and_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_memberships_on_group_id_and_role ON public.group_memberships USING btree (group_id, role);


--
-- Name: index_group_stats_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_group_stats_on_group_id ON public.group_stats USING btree (group_id);


--
-- Name: index_group_suggestions_on_group_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_group_suggestions_on_group_id ON public.group_suggestions USING btree (group_id);


--
-- Name: index_groups_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_groups_on_slug ON public.groups USING btree (slug);


--
-- Name: index_identities_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_identities_on_user_id ON public.identities USING btree (user_id);


--
-- Name: index_instances_on_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_instances_on_domain ON public.instances USING btree (domain);


--
-- Name: index_invites_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_invites_on_code ON public.invites USING btree (code);


--
-- Name: index_invites_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_invites_on_user_id ON public.invites USING btree (user_id);


--
-- Name: index_list_accounts_on_account_id_and_list_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_list_accounts_on_account_id_and_list_id ON public.list_accounts USING btree (account_id, list_id);


--
-- Name: index_list_accounts_on_follow_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_list_accounts_on_follow_id ON public.list_accounts USING btree (follow_id);


--
-- Name: index_list_accounts_on_list_id_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_list_accounts_on_list_id_and_account_id ON public.list_accounts USING btree (list_id, account_id);


--
-- Name: index_lists_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_lists_on_account_id ON public.lists USING btree (account_id);


--
-- Name: index_logs_on_event_and_app_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_logs_on_event_and_app_id ON public.logs USING btree (event, app_id);


--
-- Name: index_markers_on_user_id_and_timeline; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_markers_on_user_id_and_timeline ON public.markers USING btree (user_id, timeline);


--
-- Name: index_media_attachments_on_account_id_and_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_attachments_on_account_id_and_status_id ON public.media_attachments USING btree (account_id, status_id DESC);


--
-- Name: index_media_attachments_on_scheduled_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_attachments_on_scheduled_status_id ON public.media_attachments USING btree (scheduled_status_id);


--
-- Name: index_media_attachments_on_shortcode; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_media_attachments_on_shortcode ON public.media_attachments USING btree (shortcode);


--
-- Name: index_media_attachments_on_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_media_attachments_on_status_id ON public.media_attachments USING btree (status_id);


--
-- Name: index_mentions_on_account_id_and_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_mentions_on_account_id_and_status_id ON public.mentions USING btree (account_id, status_id);


--
-- Name: index_mentions_on_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mentions_on_status_id ON public.mentions USING btree (status_id);


--
-- Name: index_moderation_records_on_media_attachment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_moderation_records_on_media_attachment_id ON public.moderation_records USING btree (media_attachment_id);


--
-- Name: index_moderation_records_on_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_moderation_records_on_status_id ON public.moderation_records USING btree (status_id);


--
-- Name: index_mutes_on_account_id_and_target_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_mutes_on_account_id_and_target_account_id ON public.mutes USING btree (account_id, target_account_id);


--
-- Name: index_mutes_on_target_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_mutes_on_target_account_id ON public.mutes USING btree (target_account_id);


--
-- Name: index_oauth_access_grants_on_resource_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_grants_on_resource_owner_id ON public.oauth_access_grants USING btree (resource_owner_id);


--
-- Name: index_oauth_access_grants_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_grants_on_token ON public.oauth_access_grants USING btree (token);


--
-- Name: index_oauth_access_tokens_on_refresh_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_refresh_token ON public.oauth_access_tokens USING btree (refresh_token);


--
-- Name: index_oauth_access_tokens_on_resource_owner_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_access_tokens_on_resource_owner_id ON public.oauth_access_tokens USING btree (resource_owner_id);


--
-- Name: index_oauth_access_tokens_on_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_access_tokens_on_token ON public.oauth_access_tokens USING btree (token);


--
-- Name: index_oauth_applications_on_owner_id_and_owner_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_oauth_applications_on_owner_id_and_owner_type ON public.oauth_applications USING btree (owner_id, owner_type);


--
-- Name: index_oauth_applications_on_uid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_oauth_applications_on_uid ON public.oauth_applications USING btree (uid);


--
-- Name: index_on_statuses_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_on_statuses_created_at ON public.statuses USING btree (created_at) WHERE ((deleted_at IS NULL) AND (visibility = 0));


--
-- Name: index_one_time_challenges_on_object_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_one_time_challenges_on_object_type ON public.one_time_challenges USING btree (object_type);


--
-- Name: index_one_time_challenges_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_one_time_challenges_on_user_id ON public.one_time_challenges USING btree (user_id);


--
-- Name: index_one_time_challenges_on_webauthn_credential_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_one_time_challenges_on_webauthn_credential_id ON public.one_time_challenges USING btree (webauthn_credential_id);


--
-- Name: index_one_time_keys_on_device_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_one_time_keys_on_device_id ON public.one_time_keys USING btree (device_id);


--
-- Name: index_one_time_keys_on_key_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_one_time_keys_on_key_id ON public.one_time_keys USING btree (key_id);


--
-- Name: index_policies_on_version; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_policies_on_version ON public.policies USING btree (version);


--
-- Name: index_preview_cards_on_url; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_preview_cards_on_url ON public.preview_cards USING btree (url);


--
-- Name: index_preview_cards_statuses_on_status_id_and_preview_card_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_preview_cards_statuses_on_status_id_and_preview_card_id ON public.preview_cards_statuses USING btree (status_id, preview_card_id);


--
-- Name: index_report_notes_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_notes_on_account_id ON public.report_notes USING btree (account_id);


--
-- Name: index_report_notes_on_report_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_report_notes_on_report_id ON public.report_notes USING btree (report_id);


--
-- Name: index_reports_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_account_id ON public.reports USING btree (account_id);


--
-- Name: index_reports_on_target_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_reports_on_target_account_id ON public.reports USING btree (target_account_id);


--
-- Name: index_scheduled_statuses_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_scheduled_statuses_on_account_id ON public.scheduled_statuses USING btree (account_id);


--
-- Name: index_scheduled_statuses_on_scheduled_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_scheduled_statuses_on_scheduled_at ON public.scheduled_statuses USING btree (scheduled_at);


--
-- Name: index_session_activations_on_access_token_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_session_activations_on_access_token_id ON public.session_activations USING btree (access_token_id);


--
-- Name: index_session_activations_on_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_session_activations_on_session_id ON public.session_activations USING btree (session_id);


--
-- Name: index_session_activations_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_session_activations_on_user_id ON public.session_activations USING btree (user_id);


--
-- Name: index_settings_on_thing_type_and_thing_id_and_var; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_settings_on_thing_type_and_thing_id_and_var ON public.settings USING btree (thing_type, thing_id, var);


--
-- Name: index_site_uploads_on_var; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_site_uploads_on_var ON public.site_uploads USING btree (var);


--
-- Name: index_status_pins_on_account_id_and_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_status_pins_on_account_id_and_status_id ON public.status_pins USING btree (account_id, status_id);


--
-- Name: index_status_stats_on_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_status_stats_on_status_id ON public.status_stats USING btree (status_id);


--
-- Name: index_statuses_20190820; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statuses_20190820 ON public.statuses USING btree (account_id, id DESC, visibility, updated_at) WHERE (deleted_at IS NULL);


--
-- Name: index_statuses_local_20190824; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statuses_local_20190824 ON public.statuses USING btree (id DESC, account_id) WHERE ((local OR (uri IS NULL)) AND (deleted_at IS NULL) AND (visibility = 0) AND (reblog_of_id IS NULL) AND ((NOT reply) OR (in_reply_to_account_id = account_id)));


--
-- Name: index_statuses_on_in_reply_to_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statuses_on_in_reply_to_account_id ON public.statuses USING btree (in_reply_to_account_id);


--
-- Name: index_statuses_on_in_reply_to_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statuses_on_in_reply_to_id ON public.statuses USING btree (in_reply_to_id);


--
-- Name: index_statuses_on_quote_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statuses_on_quote_id ON public.statuses USING btree (quote_id);


--
-- Name: index_statuses_on_reblog_of_id_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statuses_on_reblog_of_id_and_account_id ON public.statuses USING btree (reblog_of_id, account_id);


--
-- Name: index_statuses_on_uri; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_statuses_on_uri ON public.statuses USING btree (uri);


--
-- Name: index_statuses_public_20200119; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_statuses_public_20200119 ON public.statuses USING btree (id DESC, account_id) WHERE ((deleted_at IS NULL) AND (visibility = 0) AND (reblog_of_id IS NULL) AND ((NOT reply) OR (in_reply_to_account_id = account_id)));


--
-- Name: index_statuses_tags_on_tag_id_and_status_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_statuses_tags_on_tag_id_and_status_id ON public.statuses_tags USING btree (tag_id, status_id);


--
-- Name: index_tags_on_name_lower_btree; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_name_lower_btree ON public.tags USING btree (lower((name)::text) text_pattern_ops);


--
-- Name: index_tombstones_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tombstones_on_account_id ON public.tombstones USING btree (account_id);


--
-- Name: index_tombstones_on_uri; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tombstones_on_uri ON public.tombstones USING btree (uri);


--
-- Name: index_unavailable_domains_on_domain; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_unavailable_domains_on_domain ON public.unavailable_domains USING btree (domain);


--
-- Name: index_unique_conversations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_unique_conversations ON public.account_conversations USING btree (account_id, conversation_id, participant_account_ids);


--
-- Name: index_user_invite_requests_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_user_invite_requests_on_user_id ON public.user_invite_requests USING btree (user_id);


--
-- Name: index_users_on_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_account_id ON public.users USING btree (account_id);


--
-- Name: index_users_on_confirmation_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_confirmation_token ON public.users USING btree (confirmation_token);


--
-- Name: index_users_on_created_by_application_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_created_by_application_id ON public.users USING btree (created_by_application_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_policy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_policy_id ON public.users USING btree (policy_id);


--
-- Name: index_users_on_remember_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_remember_token ON public.users USING btree (remember_token);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON public.users USING btree (reset_password_token);


--
-- Name: index_users_on_sms; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_sms ON public.users USING btree (sms);


--
-- Name: index_users_on_waitlist_position; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_waitlist_position ON public.users USING btree (waitlist_position);


--
-- Name: index_web_push_subscriptions_on_access_token_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_web_push_subscriptions_on_access_token_id ON public.web_push_subscriptions USING btree (access_token_id);


--
-- Name: index_web_push_subscriptions_on_device_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_web_push_subscriptions_on_device_token ON public.web_push_subscriptions USING btree (device_token);


--
-- Name: index_web_push_subscriptions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_web_push_subscriptions_on_user_id ON public.web_push_subscriptions USING btree (user_id);


--
-- Name: index_web_settings_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_web_settings_on_user_id ON public.web_settings USING btree (user_id);


--
-- Name: index_webauthn_credentials_on_external_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_webauthn_credentials_on_external_id ON public.webauthn_credentials USING btree (external_id);


--
-- Name: index_webauthn_credentials_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_webauthn_credentials_on_user_id ON public.webauthn_credentials USING btree (user_id);


--
-- Name: search_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX search_index ON public.accounts USING gin ((((setweight(to_tsvector('simple'::regconfig, (display_name)::text), 'A'::"char") || setweight(to_tsvector('simple'::regconfig, (username)::text), 'B'::"char")) || setweight(to_tsvector('simple'::regconfig, (COALESCE(domain, ''::character varying))::text), 'C'::"char"))));


--
-- Name: statuses_account_id_group_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statuses_account_id_group_id_created_at_idx ON public.statuses USING btree (account_id, group_id, created_at) WHERE ((deleted_at IS NULL) AND (in_reply_to_id IS NULL));


--
-- Name: statuses_created_at_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statuses_created_at_index ON public.statuses USING btree (created_at);


--
-- Name: statuses_id_group_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statuses_id_group_id_idx ON public.statuses USING btree (id, group_id) WHERE ((group_id IS NOT NULL) AND (deleted_at IS NULL));


--
-- Name: statuses_in_reply_to_id_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statuses_in_reply_to_id_account_id_idx ON public.statuses USING btree (in_reply_to_id, account_id) WHERE (deleted_at IS NULL);


--
-- Name: statuses_in_reply_to_id_created_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statuses_in_reply_to_id_created_at_idx ON public.statuses USING btree (in_reply_to_id, created_at) WHERE (deleted_at IS NULL);


--
-- Name: statuses_latest_not_replies; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statuses_latest_not_replies ON public.statuses USING btree (account_id, created_at DESC) WHERE ((deleted_at IS NULL) AND (in_reply_to_id IS NULL));


--
-- Name: statuses_quote_id_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statuses_quote_id_account_id_idx ON public.statuses USING btree (quote_id, account_id) WHERE (deleted_at IS NULL);


--
-- Name: statuses_reblog_of_id_account_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX statuses_reblog_of_id_account_id_idx ON public.statuses USING btree (reblog_of_id, account_id) WHERE (deleted_at IS NULL);


--
-- Name: tags_name_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX tags_name_idx ON public.tags USING gin (name extension_pg_trgm.gin_trgm_ops);


--
-- Name: reply_status_controversial_scores_priority_idx; Type: INDEX; Schema: queues; Owner: -
--

CREATE INDEX reply_status_controversial_scores_priority_idx ON queues.reply_status_controversial_scores USING btree (priority DESC);


--
-- Name: reply_status_trending_scores_priority_idx; Type: INDEX; Schema: queues; Owner: -
--

CREATE INDEX reply_status_trending_scores_priority_idx ON queues.reply_status_trending_scores USING btree (priority DESC);


--
-- Name: status_engagement_statistics_priority_idx; Type: INDEX; Schema: queues; Owner: -
--

CREATE INDEX status_engagement_statistics_priority_idx ON queues.status_engagement_statistics USING btree (priority DESC);


--
-- Name: status_favourite_statistics_priority_idx; Type: INDEX; Schema: queues; Owner: -
--

CREATE INDEX status_favourite_statistics_priority_idx ON queues.status_favourite_statistics USING btree (priority DESC);


--
-- Name: status_reblog_statistics_priority_idx; Type: INDEX; Schema: queues; Owner: -
--

CREATE INDEX status_reblog_statistics_priority_idx ON queues.status_reblog_statistics USING btree (priority DESC);


--
-- Name: status_reply_statistics_priority_idx; Type: INDEX; Schema: queues; Owner: -
--

CREATE INDEX status_reply_statistics_priority_idx ON queues.status_reply_statistics USING btree (priority DESC);


--
-- Name: account_followers_followers_count_account_id_idx; Type: INDEX; Schema: statistics; Owner: -
--

CREATE INDEX account_followers_followers_count_account_id_idx ON statistics.account_followers USING btree (followers_count, account_id);


--
-- Name: reply_status_controversial_scores_reply_to_status_id_score_idx; Type: INDEX; Schema: statistics; Owner: -
--

CREATE INDEX reply_status_controversial_scores_reply_to_status_id_score_idx ON statistics.reply_status_controversial_scores USING btree (reply_to_status_id, score);


--
-- Name: reply_status_trending_scores_reply_to_status_id_score_idx; Type: INDEX; Schema: statistics; Owner: -
--

CREATE INDEX reply_status_trending_scores_reply_to_status_id_score_idx ON statistics.reply_status_trending_scores USING btree (reply_to_status_id, score);


--
-- Name: trending_group_scores_group_id_idx; Type: INDEX; Schema: trending_groups; Owner: -
--

CREATE UNIQUE INDEX trending_group_scores_group_id_idx ON trending_groups.trending_group_scores USING btree (group_id);


--
-- Name: favourites_by_nonfollowers_status_id_idx; Type: INDEX; Schema: trending_statuses; Owner: -
--

CREATE UNIQUE INDEX favourites_by_nonfollowers_status_id_idx ON trending_statuses.favourites_by_nonfollowers USING btree (status_id);


--
-- Name: reblogs_by_nonfollowers_status_id_idx; Type: INDEX; Schema: trending_statuses; Owner: -
--

CREATE UNIQUE INDEX reblogs_by_nonfollowers_status_id_idx ON trending_statuses.reblogs_by_nonfollowers USING btree (status_id);


--
-- Name: recent_statuses_from_followed_accounts_status_id_account_id_idx; Type: INDEX; Schema: trending_statuses; Owner: -
--

CREATE UNIQUE INDEX recent_statuses_from_followed_accounts_status_id_account_id_idx ON trending_statuses.recent_statuses_from_followed_accounts USING btree (status_id, account_id);


--
-- Name: replies_by_nonfollowers_status_id_idx; Type: INDEX; Schema: trending_statuses; Owner: -
--

CREATE UNIQUE INDEX replies_by_nonfollowers_status_id_idx ON trending_statuses.replies_by_nonfollowers USING btree (status_id);


--
-- Name: trending_statuses_popular_status_id_idx; Type: INDEX; Schema: trending_statuses; Owner: -
--

CREATE UNIQUE INDEX trending_statuses_popular_status_id_idx ON trending_statuses.trending_statuses_popular USING btree (status_id);


--
-- Name: trending_statuses_status_id_idx; Type: INDEX; Schema: trending_statuses; Owner: -
--

CREATE UNIQUE INDEX trending_statuses_status_id_idx ON trending_statuses.trending_statuses USING btree (status_id);


--
-- Name: trending_statuses_viral_status_id_idx; Type: INDEX; Schema: trending_statuses; Owner: -
--

CREATE UNIQUE INDEX trending_statuses_viral_status_id_idx ON trending_statuses.trending_statuses_viral USING btree (status_id);


--
-- Name: trending_tag_scores_tag_id_idx; Type: INDEX; Schema: trending_tags; Owner: -
--

CREATE UNIQUE INDEX trending_tag_scores_tag_id_idx ON trending_tags.trending_tag_scores USING btree (tag_id);


--
-- Name: trending_tags_sort_order_idx; Type: INDEX; Schema: trending_tags; Owner: -
--

CREATE UNIQUE INDEX trending_tags_sort_order_idx ON trending_tags.trending_tags USING btree (sort_order);


--
-- Name: part_1_account_id_id_type_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_account_id_id_type_idx ATTACH PARTITION notifications.part_1_account_id_id_type_idx;


--
-- Name: part_1_activity_id_activity_type_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_activity_id_activity_type_idx ATTACH PARTITION notifications.part_1_activity_id_activity_type_idx;


--
-- Name: part_1_from_account_id_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_from_account_id_idx ATTACH PARTITION notifications.part_1_from_account_id_idx;


--
-- Name: part_1_id_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_id_idx ATTACH PARTITION notifications.part_1_id_idx;


--
-- Name: part_2_account_id_id_type_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_account_id_id_type_idx ATTACH PARTITION notifications.part_2_account_id_id_type_idx;


--
-- Name: part_2_activity_id_activity_type_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_activity_id_activity_type_idx ATTACH PARTITION notifications.part_2_activity_id_activity_type_idx;


--
-- Name: part_2_from_account_id_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_from_account_id_idx ATTACH PARTITION notifications.part_2_from_account_id_idx;


--
-- Name: part_2_id_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_id_idx ATTACH PARTITION notifications.part_2_id_idx;


--
-- Name: part_3_account_id_id_type_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_account_id_id_type_idx ATTACH PARTITION notifications.part_3_account_id_id_type_idx;


--
-- Name: part_3_activity_id_activity_type_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_activity_id_activity_type_idx ATTACH PARTITION notifications.part_3_activity_id_activity_type_idx;


--
-- Name: part_3_from_account_id_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_from_account_id_idx ATTACH PARTITION notifications.part_3_from_account_id_idx;


--
-- Name: part_3_id_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_id_idx ATTACH PARTITION notifications.part_3_id_idx;


--
-- Name: part_4_account_id_id_type_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_account_id_id_type_idx ATTACH PARTITION notifications.part_4_account_id_id_type_idx;


--
-- Name: part_4_activity_id_activity_type_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_activity_id_activity_type_idx ATTACH PARTITION notifications.part_4_activity_id_activity_type_idx;


--
-- Name: part_4_from_account_id_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_from_account_id_idx ATTACH PARTITION notifications.part_4_from_account_id_idx;


--
-- Name: part_4_id_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_id_idx ATTACH PARTITION notifications.part_4_id_idx;


--
-- Name: part_5_account_id_id_type_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_account_id_id_type_idx ATTACH PARTITION notifications.part_5_account_id_id_type_idx;


--
-- Name: part_5_activity_id_activity_type_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_activity_id_activity_type_idx ATTACH PARTITION notifications.part_5_activity_id_activity_type_idx;


--
-- Name: part_5_from_account_id_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_from_account_id_idx ATTACH PARTITION notifications.part_5_from_account_id_idx;


--
-- Name: part_5_id_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_id_idx ATTACH PARTITION notifications.part_5_id_idx;


--
-- Name: part_6_account_id_id_type_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_account_id_id_type_idx ATTACH PARTITION notifications.part_6_account_id_id_type_idx;


--
-- Name: part_6_activity_id_activity_type_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_activity_id_activity_type_idx ATTACH PARTITION notifications.part_6_activity_id_activity_type_idx;


--
-- Name: part_6_from_account_id_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_from_account_id_idx ATTACH PARTITION notifications.part_6_from_account_id_idx;


--
-- Name: part_6_id_idx; Type: INDEX ATTACH; Schema: notifications; Owner: -
--

ALTER INDEX public.notifications_id_idx ATTACH PARTITION notifications.part_6_id_idx;


--
-- Name: chats chat_create_from_api_view; Type: TRIGGER; Schema: api; Owner: -
--

CREATE TRIGGER chat_create_from_api_view INSTEAD OF INSERT ON api.chats FOR EACH ROW EXECUTE FUNCTION chats.chat_create_from_api_view();


--
-- Name: chats chat_delete_from_api_view; Type: TRIGGER; Schema: api; Owner: -
--

CREATE TRIGGER chat_delete_from_api_view INSTEAD OF DELETE ON api.chats FOR EACH ROW EXECUTE FUNCTION chats.chat_delete_from_api_view();


--
-- Name: chat_members chat_member_create_from_api_view; Type: TRIGGER; Schema: api; Owner: -
--

CREATE TRIGGER chat_member_create_from_api_view INSTEAD OF INSERT ON api.chat_members FOR EACH ROW EXECUTE FUNCTION chats.chat_member_create_from_api_view();


--
-- Name: chat_members chat_member_update_from_api_view; Type: TRIGGER; Schema: api; Owner: -
--

CREATE TRIGGER chat_member_update_from_api_view INSTEAD OF UPDATE ON api.chat_members FOR EACH ROW EXECUTE FUNCTION chats.chat_member_update_from_api_view();


--
-- Name: chats chat_update_from_api_view; Type: TRIGGER; Schema: api; Owner: -
--

CREATE TRIGGER chat_update_from_api_view INSTEAD OF UPDATE ON api.chats FOR EACH ROW EXECUTE FUNCTION chats.chat_update_from_api_view();


--
-- Name: trending_status_settings trending_status_setting_update_from_api_view; Type: TRIGGER; Schema: api; Owner: -
--

CREATE TRIGGER trending_status_setting_update_from_api_view INSTEAD OF UPDATE ON api.trending_status_settings FOR EACH ROW EXECUTE FUNCTION configuration.trending_status_setting_update_from_api_view();


--
-- Name: group_status_tags send_refresh_group_tag_use_cache_notification; Type: TRIGGER; Schema: cache; Owner: -
--

CREATE TRIGGER send_refresh_group_tag_use_cache_notification AFTER INSERT OR DELETE OR UPDATE ON cache.group_status_tags FOR EACH ROW EXECUTE FUNCTION cache.send_refresh_group_tag_use_cache_notification();


--
-- Name: status_tags send_refresh_tag_use_cache_notification; Type: TRIGGER; Schema: cache; Owner: -
--

CREATE TRIGGER send_refresh_tag_use_cache_notification AFTER INSERT OR DELETE OR UPDATE ON cache.status_tags FOR EACH ROW EXECUTE FUNCTION cache.send_refresh_tag_use_cache_notification();


--
-- Name: events keep_only_latest_chat_avatar_changed_event; Type: TRIGGER; Schema: chat_events; Owner: -
--

CREATE TRIGGER keep_only_latest_chat_avatar_changed_event AFTER INSERT ON chat_events.events REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chat_events.keep_only_latest_chat_avatar_changed_event();


--
-- Name: chat_silences keep_only_latest_chat_silence_event; Type: TRIGGER; Schema: chat_events; Owner: -
--

CREATE TRIGGER keep_only_latest_chat_silence_event AFTER INSERT ON chat_events.chat_silences REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chat_events.keep_only_latest_chat_silence_event();


--
-- Name: chat_unsilences keep_only_latest_chat_unsilence_event; Type: TRIGGER; Schema: chat_events; Owner: -
--

CREATE TRIGGER keep_only_latest_chat_unsilence_event AFTER INSERT ON chat_events.chat_unsilences REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chat_events.keep_only_latest_chat_unsilence_event();


--
-- Name: member_avatar_changes keep_only_latest_member_avatar_changed_event; Type: TRIGGER; Schema: chat_events; Owner: -
--

CREATE TRIGGER keep_only_latest_member_avatar_changed_event AFTER INSERT ON chat_events.member_avatar_changes REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chat_events.keep_only_latest_member_avatar_changed_event();


--
-- Name: member_latest_read_message_changes keep_only_latest_member_latest_read_message_changed_event; Type: TRIGGER; Schema: chat_events; Owner: -
--

CREATE TRIGGER keep_only_latest_member_latest_read_message_changed_event AFTER INSERT ON chat_events.member_latest_read_message_changes REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chat_events.keep_only_latest_member_latest_read_message_changed_event();


--
-- Name: message_edits keep_only_latest_message_edited_event; Type: TRIGGER; Schema: chat_events; Owner: -
--

CREATE TRIGGER keep_only_latest_message_edited_event AFTER INSERT ON chat_events.message_edits REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chat_events.keep_only_latest_message_edited_event();


--
-- Name: message_reactions_changes keep_only_latest_message_reactions_changed_event; Type: TRIGGER; Schema: chat_events; Owner: -
--

CREATE TRIGGER keep_only_latest_message_reactions_changed_event AFTER INSERT ON chat_events.message_reactions_changes REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chat_events.keep_only_latest_message_reactions_changed_event();


--
-- Name: subscriber_leaves keep_only_latest_subscriber_left_event; Type: TRIGGER; Schema: chat_events; Owner: -
--

CREATE TRIGGER keep_only_latest_subscriber_left_event AFTER INSERT ON chat_events.subscriber_leaves REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chat_events.keep_only_latest_subscriber_left_event();


--
-- Name: subscriber_rejoins keep_only_latest_subscriber_rejoined_event; Type: TRIGGER; Schema: chat_events; Owner: -
--

CREATE TRIGGER keep_only_latest_subscriber_rejoined_event AFTER INSERT ON chat_events.subscriber_rejoins REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chat_events.keep_only_latest_subscriber_rejoined_event();


--
-- Name: chats archive_deleted_chats; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER archive_deleted_chats BEFORE DELETE ON chats.chats FOR EACH ROW EXECUTE FUNCTION chats.archive_deleted_chats();


--
-- Name: members archive_deleted_members; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER archive_deleted_members BEFORE DELETE ON chats.members FOR EACH ROW EXECUTE FUNCTION chats.archive_deleted_members();


--
-- Name: message_text archive_deleted_message_text; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER archive_deleted_message_text BEFORE DELETE ON chats.message_text FOR EACH ROW EXECUTE FUNCTION chats.archive_deleted_message_text();


--
-- Name: messages archive_deleted_messages; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER archive_deleted_messages BEFORE DELETE ON chats.messages FOR EACH ROW EXECUTE FUNCTION chats.archive_deleted_messages();


--
-- Name: chats create_chat_creation_events; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER create_chat_creation_events AFTER INSERT ON chats.chats REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.create_chat_creation_events();


--
-- Name: chats create_chat_deletion_events; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER create_chat_deletion_events AFTER DELETE ON chats.chats REFERENCING OLD TABLE AS old_data FOR EACH STATEMENT EXECUTE FUNCTION chats.create_chat_deletion_events();


--
-- Name: chat_message_expiration_changes create_chat_message_expiration_change_events; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER create_chat_message_expiration_change_events AFTER INSERT ON chats.chat_message_expiration_changes REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.create_chat_message_expiration_change_events();


--
-- Name: members create_chat_silenced_events; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER create_chat_silenced_events AFTER UPDATE ON chats.members REFERENCING OLD TABLE AS old_data NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.create_chat_silenced_events();


--
-- Name: members create_chat_unsilenced_events; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER create_chat_unsilenced_events AFTER UPDATE ON chats.members REFERENCING OLD TABLE AS old_data NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.create_chat_unsilenced_events();


--
-- Name: members create_member_invited_events; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER create_member_invited_events AFTER INSERT ON chats.members REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.create_member_invited_events();


--
-- Name: members create_member_joined_events; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER create_member_joined_events AFTER UPDATE ON chats.members REFERENCING OLD TABLE AS old_data NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.create_member_joined_events();


--
-- Name: members create_member_latest_read_message_changed_events; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER create_member_latest_read_message_changed_events AFTER UPDATE ON chats.members REFERENCING OLD TABLE AS old_data NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.create_member_latest_read_message_changed_events();


--
-- Name: members create_member_left_events; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER create_member_left_events AFTER UPDATE ON chats.members REFERENCING OLD TABLE AS old_data NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.create_member_left_events();


--
-- Name: members create_member_rejoined_events; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER create_member_rejoined_events AFTER UPDATE ON chats.members REFERENCING OLD TABLE AS old_data NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.create_member_rejoined_events();


--
-- Name: messages create_message_creation_events; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER create_message_creation_events AFTER INSERT ON chats.messages REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.create_message_creation_events();


--
-- Name: messages create_message_deletion_events; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER create_message_deletion_events AFTER DELETE ON chats.messages REFERENCING OLD TABLE AS old_data FOR EACH STATEMENT EXECUTE FUNCTION chats.create_message_deletion_events();


--
-- Name: hidden_messages create_message_hidden_events; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER create_message_hidden_events AFTER INSERT ON chats.hidden_messages REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.create_message_hidden_events();


--
-- Name: reactions create_message_reactions_changed_events_after_delete; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER create_message_reactions_changed_events_after_delete AFTER DELETE ON chats.reactions REFERENCING OLD TABLE AS old_data FOR EACH STATEMENT EXECUTE FUNCTION chats.create_message_reactions_changed_events_after_delete();


--
-- Name: reactions create_message_reactions_changed_events_after_insert; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER create_message_reactions_changed_events_after_insert AFTER INSERT ON chats.reactions REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.create_message_reactions_changed_events_after_insert();


--
-- Name: members create_subscriber_left_events; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER create_subscriber_left_events AFTER UPDATE ON chats.members REFERENCING OLD TABLE AS old_data NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.create_subscriber_left_events();


--
-- Name: members create_subscriber_rejoined_events; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER create_subscriber_rejoined_events AFTER UPDATE ON chats.members REFERENCING OLD TABLE AS old_data NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.create_subscriber_rejoined_events();


--
-- Name: members delete_chat_when_last_active_member_is_deleted; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER delete_chat_when_last_active_member_is_deleted AFTER DELETE ON chats.members REFERENCING OLD TABLE AS old_data FOR EACH STATEMENT EXECUTE FUNCTION chats.delete_chat_when_last_active_member_is_deleted();


--
-- Name: members delete_chat_when_last_member_becomes_inactive; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER delete_chat_when_last_member_becomes_inactive AFTER UPDATE ON chats.members REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.delete_chat_when_last_member_becomes_inactive();


--
-- Name: messages delete_message_creation_events; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER delete_message_creation_events AFTER DELETE ON chats.messages REFERENCING OLD TABLE AS old_data FOR EACH STATEMENT EXECUTE FUNCTION chats.delete_message_creation_events();


--
-- Name: messages delete_message_edit_events; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER delete_message_edit_events AFTER DELETE ON chats.messages REFERENCING OLD TABLE AS old_data FOR EACH STATEMENT EXECUTE FUNCTION chats.delete_message_edit_events();


--
-- Name: messages delete_message_notifications; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER delete_message_notifications AFTER DELETE ON chats.messages REFERENCING OLD TABLE AS old_data FOR EACH STATEMENT EXECUTE FUNCTION chats.delete_message_notifications();


--
-- Name: members delete_message_notifications_when_leaving_chat; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER delete_message_notifications_when_leaving_chat AFTER UPDATE ON chats.members FOR EACH ROW EXECUTE FUNCTION chats.delete_message_notifications_when_leaving_chat();


--
-- Name: hidden_messages disallow_hidden_message_update; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER disallow_hidden_message_update AFTER UPDATE ON chats.hidden_messages FOR EACH STATEMENT EXECUTE FUNCTION chats.disallow_hidden_message_update();


--
-- Name: hidden_messages disallow_hiding_own_messages; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER disallow_hiding_own_messages AFTER INSERT ON chats.hidden_messages REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.disallow_hiding_own_messages();


--
-- Name: members disallow_member_primary_key_change; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER disallow_member_primary_key_change AFTER UPDATE ON chats.members REFERENCING OLD TABLE AS old_data NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.disallow_member_primary_key_change();


--
-- Name: hidden_messages only_allow_hiding_visible_messages; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER only_allow_hiding_visible_messages AFTER INSERT ON chats.hidden_messages REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.only_allow_hiding_visible_messages();


--
-- Name: reactions set_latest_message_reaction_delete; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER set_latest_message_reaction_delete AFTER DELETE ON chats.reactions FOR EACH ROW EXECUTE FUNCTION chats.set_latest_message_reaction_delete();


--
-- Name: reactions set_latest_message_reaction_insert; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER set_latest_message_reaction_insert AFTER INSERT ON chats.reactions FOR EACH ROW EXECUTE FUNCTION chats.set_latest_message_reaction_insert();


--
-- Name: members set_member_accepted_when_rejoining_chat; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER set_member_accepted_when_rejoining_chat BEFORE UPDATE ON chats.members FOR EACH ROW EXECUTE FUNCTION chats.set_member_accepted_when_rejoining_chat();


--
-- Name: messages set_member_active_when_creating_message; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER set_member_active_when_creating_message AFTER INSERT ON chats.messages FOR EACH ROW EXECUTE FUNCTION chats.set_member_active_when_creating_message();


--
-- Name: messages set_message_expiration; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER set_message_expiration BEFORE INSERT ON chats.messages FOR EACH ROW EXECUTE FUNCTION chats.set_message_expiration();


--
-- Name: members update_chat_subscriber_counts_after_member_delete; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER update_chat_subscriber_counts_after_member_delete AFTER DELETE ON chats.members REFERENCING OLD TABLE AS old_data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_chat_subscriber_counts_after_member_delete();


--
-- Name: members update_chat_subscriber_counts_after_member_insert; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER update_chat_subscriber_counts_after_member_insert AFTER INSERT ON chats.members REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_chat_subscriber_counts_after_member_insert();


--
-- Name: members update_chat_subscriber_counts_after_member_update; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER update_chat_subscriber_counts_after_member_update AFTER UPDATE ON chats.members REFERENCING OLD TABLE AS old_data NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_chat_subscriber_counts_after_member_update();


--
-- Name: messages update_last_message_read_created_at_when_message_created; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER update_last_message_read_created_at_when_message_created AFTER INSERT ON chats.messages FOR EACH ROW EXECUTE FUNCTION chats.update_last_message_read_created_at_when_message_created();


--
-- Name: members update_member_list_after_member_delete; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER update_member_list_after_member_delete AFTER DELETE ON chats.members REFERENCING OLD TABLE AS old_data FOR EACH STATEMENT EXECUTE FUNCTION chats.update_member_list_after_member_delete();


--
-- Name: members update_member_list_after_member_insert; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER update_member_list_after_member_insert AFTER INSERT ON chats.members REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.update_member_list_after_member_insert();


--
-- Name: members update_member_list_after_member_update; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER update_member_list_after_member_update AFTER UPDATE ON chats.members FOR EACH ROW EXECUTE FUNCTION chats.update_member_list_after_member_update();


--
-- Name: members update_member_oldest_visible_when_leaving_or_rejoining_chat; Type: TRIGGER; Schema: chats; Owner: -
--

CREATE TRIGGER update_member_oldest_visible_when_leaving_or_rejoining_chat BEFORE UPDATE ON chats.members FOR EACH ROW EXECUTE FUNCTION chats.update_member_oldest_visible_when_leaving_or_rejoining_chat();


--
-- Name: elwood send_elwood_reload_configuration_notification; Type: TRIGGER; Schema: configuration; Owner: -
--

CREATE TRIGGER send_elwood_reload_configuration_notification AFTER INSERT OR DELETE OR UPDATE ON configuration.elwood FOR EACH ROW EXECUTE FUNCTION configuration.send_elwood_reload_configuration_notification();


--
-- Name: feature_settings validate_setting; Type: TRIGGER; Schema: configuration; Owner: -
--

CREATE TRIGGER validate_setting BEFORE INSERT OR UPDATE ON configuration.feature_settings FOR EACH ROW EXECUTE FUNCTION configuration.validate_feature_setting();


--
-- Name: votes update_poll_option_statistics_after_delete; Type: TRIGGER; Schema: polls; Owner: -
--

CREATE TRIGGER update_poll_option_statistics_after_delete AFTER DELETE ON polls.votes REFERENCING OLD TABLE AS old_data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_poll_option_statistics_after_delete();


--
-- Name: votes update_poll_option_statistics_after_insert; Type: TRIGGER; Schema: polls; Owner: -
--

CREATE TRIGGER update_poll_option_statistics_after_insert AFTER INSERT ON polls.votes REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_poll_option_statistics_after_insert();


--
-- Name: accounts create_chat_avatar_change_events; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER create_chat_avatar_change_events AFTER UPDATE ON public.accounts REFERENCING OLD TABLE AS old_data NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.create_chat_avatar_change_events();


--
-- Name: accounts create_member_avatar_change_events; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER create_member_avatar_change_events AFTER UPDATE ON public.accounts REFERENCING OLD TABLE AS old_data NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.create_member_avatar_change_events();


--
-- Name: media_attachments create_message_edit_events; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER create_message_edit_events AFTER UPDATE ON public.media_attachments REFERENCING OLD TABLE AS old_data NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION chats.create_message_edit_events();


--
-- Name: statuses create_reply_status_scores; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER create_reply_status_scores AFTER INSERT ON public.statuses FOR EACH ROW WHEN ((new.in_reply_to_id IS NOT NULL)) EXECUTE FUNCTION queues.create_reply_status_scores();


--
-- Name: group_memberships disallow_group_owner_membership_deletions; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER disallow_group_owner_membership_deletions AFTER DELETE ON public.group_memberships REFERENCING OLD TABLE AS old_data FOR EACH STATEMENT EXECUTE FUNCTION public.disallow_group_owner_membership_deletions();


--
-- Name: users queue_account_index_refresh; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER queue_account_index_refresh AFTER UPDATE ON public.users FOR EACH ROW WHEN (((old.disabled IS DISTINCT FROM new.disabled) OR ((old.email)::text IS DISTINCT FROM (new.email)::text) OR (old.admin IS DISTINCT FROM new.admin) OR (old.moderator IS DISTINCT FROM new.moderator) OR ((old.sms)::text IS DISTINCT FROM (new.sms)::text) OR (old.last_sign_in_ip IS DISTINCT FROM new.last_sign_in_ip))) EXECUTE FUNCTION queues.queue_account_index_refresh();


--
-- Name: accounts queue_account_index_refresh_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER queue_account_index_refresh_insert AFTER INSERT ON public.accounts FOR EACH ROW EXECUTE FUNCTION queues.queue_account_index_refresh();


--
-- Name: accounts queue_account_index_refresh_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER queue_account_index_refresh_update AFTER UPDATE ON public.accounts FOR EACH ROW WHEN ((((old.display_name)::text IS DISTINCT FROM (new.display_name)::text) OR ((old.username)::text IS DISTINCT FROM (new.username)::text) OR (old.suspended_at IS DISTINCT FROM new.suspended_at) OR ((old.avatar_file_name)::text IS DISTINCT FROM (new.avatar_file_name)::text) OR ((old.header_file_name)::text IS DISTINCT FROM (new.header_file_name)::text) OR (old.website IS DISTINCT FROM new.website) OR (old.note IS DISTINCT FROM new.note) OR (old.location IS DISTINCT FROM new.location) OR (old.verified IS DISTINCT FROM new.verified))) EXECUTE FUNCTION queues.queue_account_index_refresh();


--
-- Name: statuses queue_status_index_refresh_insert_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER queue_status_index_refresh_insert_delete AFTER INSERT OR DELETE ON public.statuses FOR EACH ROW EXECUTE FUNCTION queues.queue_status_index_refresh();


--
-- Name: statuses queue_status_index_refresh_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER queue_status_index_refresh_update AFTER UPDATE ON public.statuses FOR EACH ROW WHEN (((old.text IS DISTINCT FROM new.text) OR (old.deleted_at IS DISTINCT FROM new.deleted_at) OR (old.visibility IS DISTINCT FROM new.visibility))) EXECUTE FUNCTION queues.queue_status_index_refresh();


--
-- Name: tags queue_tag_index_refresh_insert_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER queue_tag_index_refresh_insert_delete AFTER INSERT OR DELETE ON public.tags FOR EACH ROW EXECUTE FUNCTION queues.queue_tag_index_refresh();


--
-- Name: tags queue_tag_index_refresh_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER queue_tag_index_refresh_update AFTER UPDATE ON public.tags FOR EACH ROW WHEN ((((old.name)::text IS DISTINCT FROM (new.name)::text) OR (old.reviewed_at IS DISTINCT FROM new.reviewed_at) OR (old.last_status_at IS DISTINCT FROM new.last_status_at))) EXECUTE FUNCTION queues.queue_tag_index_refresh();


--
-- Name: follows update_account_follow_statistics_after_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_account_follow_statistics_after_delete AFTER DELETE ON public.follows REFERENCING OLD TABLE AS old_data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_account_follow_statistics_after_delete();


--
-- Name: follows update_account_follow_statistics_after_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_account_follow_statistics_after_insert AFTER INSERT ON public.follows REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_account_follow_statistics_after_insert();


--
-- Name: follows update_account_follow_statistics_after_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_account_follow_statistics_after_update AFTER UPDATE ON public.follows REFERENCING OLD TABLE AS old_data NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_account_follow_statistics_after_update();


--
-- Name: statuses update_account_status_statistics_after_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_account_status_statistics_after_delete AFTER DELETE ON public.statuses REFERENCING OLD TABLE AS old_data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_account_status_statistics_after_delete();


--
-- Name: statuses update_account_status_statistics_after_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_account_status_statistics_after_insert AFTER INSERT ON public.statuses REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_account_status_statistics_after_insert();


--
-- Name: statuses update_account_status_statistics_after_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_account_status_statistics_after_update AFTER UPDATE ON public.statuses REFERENCING OLD TABLE AS old_data NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_account_status_statistics_after_update();


--
-- Name: groups update_group; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_group BEFORE UPDATE ON public.groups FOR EACH ROW EXECUTE FUNCTION public.update_group();


--
-- Name: statuses_tags update_group_status_tags_after_statuses_tags_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_group_status_tags_after_statuses_tags_insert AFTER INSERT ON public.statuses_tags REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION cache.update_group_status_tags_after_statuses_tags_insert();


--
-- Name: statuses update_group_status_tags_after_statuses_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_group_status_tags_after_statuses_update AFTER UPDATE ON public.statuses REFERENCING OLD TABLE AS old_data NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION cache.update_group_status_tags_after_statuses_update();


--
-- Name: favourites update_status_favourite_statistics_after_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_status_favourite_statistics_after_delete AFTER DELETE ON public.favourites REFERENCING OLD TABLE AS old_data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_status_favourite_statistics_after_delete();


--
-- Name: favourites update_status_favourite_statistics_after_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_status_favourite_statistics_after_insert AFTER INSERT ON public.favourites REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_status_favourite_statistics_after_insert();


--
-- Name: favourites update_status_favourite_statistics_after_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_status_favourite_statistics_after_update AFTER UPDATE ON public.favourites REFERENCING OLD TABLE AS old_data NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_status_favourite_statistics_after_update();


--
-- Name: statuses update_status_statistics_after_delete; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_status_statistics_after_delete AFTER DELETE ON public.statuses REFERENCING OLD TABLE AS old_data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_status_statistics_after_delete();


--
-- Name: statuses update_status_statistics_after_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_status_statistics_after_insert AFTER INSERT ON public.statuses REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_status_statistics_after_insert();


--
-- Name: statuses update_status_statistics_after_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_status_statistics_after_update AFTER UPDATE ON public.statuses FOR EACH ROW EXECUTE FUNCTION queues.update_status_statistics_after_update();


--
-- Name: statuses_tags update_status_tags_after_statuses_tags_insert; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_status_tags_after_statuses_tags_insert AFTER INSERT ON public.statuses_tags REFERENCING NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION cache.update_status_tags_after_statuses_tags_insert();


--
-- Name: statuses update_status_tags_after_statuses_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER update_status_tags_after_statuses_update AFTER UPDATE ON public.statuses REFERENCING OLD TABLE AS old_data NEW TABLE AS new_data FOR EACH STATEMENT EXECUTE FUNCTION cache.update_status_tags_after_statuses_update();


--
-- Name: account_follower_statistics send_notification; Type: TRIGGER; Schema: queues; Owner: -
--

CREATE TRIGGER send_notification AFTER INSERT ON queues.account_follower_statistics FOR EACH STATEMENT EXECUTE FUNCTION queues.send_notification('process_account_follower_statistics_queue');


--
-- Name: account_following_statistics send_notification; Type: TRIGGER; Schema: queues; Owner: -
--

CREATE TRIGGER send_notification AFTER INSERT ON queues.account_following_statistics FOR EACH STATEMENT EXECUTE FUNCTION queues.send_notification('process_account_following_statistics_queue');


--
-- Name: account_status_statistics send_notification; Type: TRIGGER; Schema: queues; Owner: -
--

CREATE TRIGGER send_notification AFTER INSERT ON queues.account_status_statistics FOR EACH STATEMENT EXECUTE FUNCTION queues.send_notification('process_account_status_statistics_queue');


--
-- Name: chat_events send_notification; Type: TRIGGER; Schema: queues; Owner: -
--

CREATE TRIGGER send_notification AFTER INSERT ON queues.chat_events FOR EACH STATEMENT EXECUTE FUNCTION queues.send_notification('process_chat_events_queue');


--
-- Name: chat_subscribers send_notification; Type: TRIGGER; Schema: queues; Owner: -
--

CREATE TRIGGER send_notification AFTER INSERT ON queues.chat_subscribers FOR EACH STATEMENT EXECUTE FUNCTION queues.send_notification('process_chat_subscribers_queue');


--
-- Name: poll_option_statistics send_notification; Type: TRIGGER; Schema: queues; Owner: -
--

CREATE TRIGGER send_notification AFTER INSERT ON queues.poll_option_statistics FOR EACH STATEMENT EXECUTE FUNCTION queues.send_notification('process_poll_option_statistics_queue');


--
-- Name: reply_status_controversial_scores send_notification; Type: TRIGGER; Schema: queues; Owner: -
--

CREATE TRIGGER send_notification AFTER INSERT ON queues.reply_status_controversial_scores FOR EACH STATEMENT EXECUTE FUNCTION queues.send_notification('process_reply_status_controversial_scores_queue');


--
-- Name: reply_status_trending_scores send_notification; Type: TRIGGER; Schema: queues; Owner: -
--

CREATE TRIGGER send_notification AFTER INSERT ON queues.reply_status_trending_scores FOR EACH STATEMENT EXECUTE FUNCTION queues.send_notification('process_reply_status_trending_scores_queue');


--
-- Name: status_engagement_statistics send_notification; Type: TRIGGER; Schema: queues; Owner: -
--

CREATE TRIGGER send_notification AFTER INSERT ON queues.status_engagement_statistics FOR EACH STATEMENT EXECUTE FUNCTION queues.send_notification('process_status_engagement_statistics_queue');


--
-- Name: status_favourite_statistics send_notification; Type: TRIGGER; Schema: queues; Owner: -
--

CREATE TRIGGER send_notification AFTER INSERT ON queues.status_favourite_statistics FOR EACH STATEMENT EXECUTE FUNCTION queues.send_notification('process_status_favourite_statistics_queue');


--
-- Name: status_reblog_statistics send_notification; Type: TRIGGER; Schema: queues; Owner: -
--

CREATE TRIGGER send_notification AFTER INSERT ON queues.status_reblog_statistics FOR EACH STATEMENT EXECUTE FUNCTION queues.send_notification('process_status_reblog_statistics_queue');


--
-- Name: status_reply_statistics send_notification; Type: TRIGGER; Schema: queues; Owner: -
--

CREATE TRIGGER send_notification AFTER INSERT ON queues.status_reply_statistics FOR EACH STATEMENT EXECUTE FUNCTION queues.send_notification('process_status_reply_statistics_queue');


--
-- Name: account_followers queue_account_index_refresh; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER queue_account_index_refresh AFTER INSERT OR UPDATE ON statistics.account_followers FOR EACH ROW EXECUTE FUNCTION queues.queue_account_index_refresh();


--
-- Name: account_following queue_account_index_refresh; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER queue_account_index_refresh AFTER INSERT OR UPDATE ON statistics.account_following FOR EACH ROW EXECUTE FUNCTION queues.queue_account_index_refresh();


--
-- Name: account_statuses queue_account_index_refresh; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER queue_account_index_refresh AFTER INSERT OR UPDATE ON statistics.account_statuses FOR EACH ROW EXECUTE FUNCTION queues.queue_account_index_refresh();


--
-- Name: status_favourites queue_status_index_refresh; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER queue_status_index_refresh AFTER INSERT OR UPDATE ON statistics.status_favourites FOR EACH ROW EXECUTE FUNCTION queues.queue_status_index_refresh();


--
-- Name: status_reblogs queue_status_index_refresh; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER queue_status_index_refresh AFTER INSERT OR UPDATE ON statistics.status_reblogs FOR EACH ROW EXECUTE FUNCTION queues.queue_status_index_refresh();


--
-- Name: status_favourites update_reply_status_controversial_scores_after_delete; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_reply_status_controversial_scores_after_delete AFTER DELETE ON statistics.status_favourites REFERENCING OLD TABLE AS data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_reply_status_controversial_scores();


--
-- Name: status_reblogs update_reply_status_controversial_scores_after_delete; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_reply_status_controversial_scores_after_delete AFTER DELETE ON statistics.status_reblogs REFERENCING OLD TABLE AS data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_reply_status_controversial_scores();


--
-- Name: status_replies update_reply_status_controversial_scores_after_delete; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_reply_status_controversial_scores_after_delete AFTER DELETE ON statistics.status_replies REFERENCING OLD TABLE AS data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_reply_status_controversial_scores();


--
-- Name: status_favourites update_reply_status_controversial_scores_after_insert; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_reply_status_controversial_scores_after_insert AFTER INSERT ON statistics.status_favourites REFERENCING NEW TABLE AS data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_reply_status_controversial_scores();


--
-- Name: status_reblogs update_reply_status_controversial_scores_after_insert; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_reply_status_controversial_scores_after_insert AFTER INSERT ON statistics.status_reblogs REFERENCING NEW TABLE AS data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_reply_status_controversial_scores();


--
-- Name: status_replies update_reply_status_controversial_scores_after_insert; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_reply_status_controversial_scores_after_insert AFTER INSERT ON statistics.status_replies REFERENCING NEW TABLE AS data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_reply_status_controversial_scores();


--
-- Name: status_favourites update_reply_status_controversial_scores_after_update; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_reply_status_controversial_scores_after_update AFTER UPDATE ON statistics.status_favourites REFERENCING NEW TABLE AS data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_reply_status_controversial_scores();


--
-- Name: status_reblogs update_reply_status_controversial_scores_after_update; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_reply_status_controversial_scores_after_update AFTER UPDATE ON statistics.status_reblogs REFERENCING NEW TABLE AS data FOR EACH ROW WHEN ((new.rebloggers_count <> old.rebloggers_count)) EXECUTE FUNCTION queues.update_reply_status_controversial_scores_for_each_row();


--
-- Name: status_replies update_reply_status_controversial_scores_after_update; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_reply_status_controversial_scores_after_update AFTER UPDATE ON statistics.status_replies REFERENCING NEW TABLE AS data FOR EACH ROW WHEN ((new.repliers_count <> old.repliers_count)) EXECUTE FUNCTION queues.update_reply_status_controversial_scores_for_each_row();


--
-- Name: status_engagement update_reply_status_trending_scores_after_delete; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_reply_status_trending_scores_after_delete AFTER DELETE ON statistics.status_engagement REFERENCING OLD TABLE AS data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_reply_status_trending_scores();


--
-- Name: status_engagement update_reply_status_trending_scores_after_insert; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_reply_status_trending_scores_after_insert AFTER INSERT ON statistics.status_engagement REFERENCING NEW TABLE AS data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_reply_status_trending_scores();


--
-- Name: status_engagement update_reply_status_trending_scores_after_update; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_reply_status_trending_scores_after_update AFTER UPDATE ON statistics.status_engagement REFERENCING NEW TABLE AS data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_reply_status_trending_scores();


--
-- Name: status_favourites update_status_engagement_statistics_after_delete; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_status_engagement_statistics_after_delete AFTER DELETE ON statistics.status_favourites REFERENCING OLD TABLE AS data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_status_engagement_statistics();


--
-- Name: status_reblogs update_status_engagement_statistics_after_delete; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_status_engagement_statistics_after_delete AFTER DELETE ON statistics.status_reblogs REFERENCING OLD TABLE AS data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_status_engagement_statistics();


--
-- Name: status_replies update_status_engagement_statistics_after_delete; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_status_engagement_statistics_after_delete AFTER DELETE ON statistics.status_replies REFERENCING OLD TABLE AS data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_status_engagement_statistics();


--
-- Name: status_favourites update_status_engagement_statistics_after_insert; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_status_engagement_statistics_after_insert AFTER INSERT ON statistics.status_favourites REFERENCING NEW TABLE AS data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_status_engagement_statistics();


--
-- Name: status_reblogs update_status_engagement_statistics_after_insert; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_status_engagement_statistics_after_insert AFTER INSERT ON statistics.status_reblogs REFERENCING NEW TABLE AS data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_status_engagement_statistics();


--
-- Name: status_replies update_status_engagement_statistics_after_insert; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_status_engagement_statistics_after_insert AFTER INSERT ON statistics.status_replies REFERENCING NEW TABLE AS data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_status_engagement_statistics();


--
-- Name: status_favourites update_status_engagement_statistics_after_update; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_status_engagement_statistics_after_update AFTER UPDATE ON statistics.status_favourites REFERENCING NEW TABLE AS data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_status_engagement_statistics();


--
-- Name: status_reblogs update_status_engagement_statistics_after_update; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_status_engagement_statistics_after_update AFTER INSERT ON statistics.status_reblogs REFERENCING NEW TABLE AS data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_status_engagement_statistics();


--
-- Name: status_replies update_status_engagement_statistics_after_update; Type: TRIGGER; Schema: statistics; Owner: -
--

CREATE TRIGGER update_status_engagement_statistics_after_update AFTER INSERT ON statistics.status_replies REFERENCING NEW TABLE AS data FOR EACH STATEMENT EXECUTE FUNCTION queues.update_status_engagement_statistics();


--
-- Name: accounts archive_deleted_accounts; Type: TRIGGER; Schema: tv; Owner: -
--

CREATE TRIGGER archive_deleted_accounts BEFORE DELETE ON tv.accounts FOR EACH ROW WHEN ((old.p_profile_id IS NOT NULL)) EXECUTE FUNCTION tv.archive_deleted_accounts();


--
-- Name: group_status_tags group_status_tags_account_id_fkey; Type: FK CONSTRAINT; Schema: cache; Owner: -
--

ALTER TABLE ONLY cache.group_status_tags
    ADD CONSTRAINT group_status_tags_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: group_status_tags group_status_tags_group_id_fkey; Type: FK CONSTRAINT; Schema: cache; Owner: -
--

ALTER TABLE ONLY cache.group_status_tags
    ADD CONSTRAINT group_status_tags_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: group_status_tags group_status_tags_status_id_tag_id_fkey; Type: FK CONSTRAINT; Schema: cache; Owner: -
--

ALTER TABLE ONLY cache.group_status_tags
    ADD CONSTRAINT group_status_tags_status_id_tag_id_fkey FOREIGN KEY (status_id, tag_id) REFERENCES public.statuses_tags(status_id, tag_id) ON DELETE CASCADE;


--
-- Name: status_tags status_tags_account_id_fkey; Type: FK CONSTRAINT; Schema: cache; Owner: -
--

ALTER TABLE ONLY cache.status_tags
    ADD CONSTRAINT status_tags_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: status_tags status_tags_status_id_tag_id_fkey; Type: FK CONSTRAINT; Schema: cache; Owner: -
--

ALTER TABLE ONLY cache.status_tags
    ADD CONSTRAINT status_tags_status_id_tag_id_fkey FOREIGN KEY (status_id, tag_id) REFERENCES public.statuses_tags(status_id, tag_id) ON DELETE CASCADE;


--
-- Name: chat_message_expiration_changes chat_message_expiration_changes_event_id_fkey; Type: FK CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.chat_message_expiration_changes
    ADD CONSTRAINT chat_message_expiration_changes_event_id_fkey FOREIGN KEY (event_id) REFERENCES chat_events.events(event_id) ON DELETE CASCADE;


--
-- Name: chat_silences chat_silences_event_id_fkey; Type: FK CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.chat_silences
    ADD CONSTRAINT chat_silences_event_id_fkey FOREIGN KEY (event_id) REFERENCES chat_events.events(event_id) ON DELETE CASCADE;


--
-- Name: chat_unsilences chat_unsilences_event_id_fkey; Type: FK CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.chat_unsilences
    ADD CONSTRAINT chat_unsilences_event_id_fkey FOREIGN KEY (event_id) REFERENCES chat_events.events(event_id) ON DELETE CASCADE;


--
-- Name: member_avatar_changes member_avatar_changes_event_id_fkey; Type: FK CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.member_avatar_changes
    ADD CONSTRAINT member_avatar_changes_event_id_fkey FOREIGN KEY (event_id) REFERENCES chat_events.events(event_id) ON DELETE CASCADE;


--
-- Name: member_invitations member_invitations_event_id_fkey; Type: FK CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.member_invitations
    ADD CONSTRAINT member_invitations_event_id_fkey FOREIGN KEY (event_id) REFERENCES chat_events.events(event_id) ON DELETE CASCADE;


--
-- Name: member_joins member_joins_event_id_fkey; Type: FK CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.member_joins
    ADD CONSTRAINT member_joins_event_id_fkey FOREIGN KEY (event_id) REFERENCES chat_events.events(event_id) ON DELETE CASCADE;


--
-- Name: member_latest_read_message_changes member_latest_read_message_changes_event_id_fkey; Type: FK CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.member_latest_read_message_changes
    ADD CONSTRAINT member_latest_read_message_changes_event_id_fkey FOREIGN KEY (event_id) REFERENCES chat_events.events(event_id) ON DELETE CASCADE;


--
-- Name: member_leaves member_leaves_event_id_fkey; Type: FK CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.member_leaves
    ADD CONSTRAINT member_leaves_event_id_fkey FOREIGN KEY (event_id) REFERENCES chat_events.events(event_id) ON DELETE CASCADE;


--
-- Name: member_rejoins member_rejoins_event_id_fkey; Type: FK CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.member_rejoins
    ADD CONSTRAINT member_rejoins_event_id_fkey FOREIGN KEY (event_id) REFERENCES chat_events.events(event_id) ON DELETE CASCADE;


--
-- Name: message_creations message_creations_event_id_fkey; Type: FK CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.message_creations
    ADD CONSTRAINT message_creations_event_id_fkey FOREIGN KEY (event_id) REFERENCES chat_events.events(event_id) ON DELETE CASCADE;


--
-- Name: message_deletions message_deletions_event_id_fkey; Type: FK CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.message_deletions
    ADD CONSTRAINT message_deletions_event_id_fkey FOREIGN KEY (event_id) REFERENCES chat_events.events(event_id) ON DELETE CASCADE;


--
-- Name: message_edits message_edits_event_id_fkey; Type: FK CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.message_edits
    ADD CONSTRAINT message_edits_event_id_fkey FOREIGN KEY (event_id) REFERENCES chat_events.events(event_id) ON DELETE CASCADE;


--
-- Name: message_hides message_hides_event_id_fkey; Type: FK CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.message_hides
    ADD CONSTRAINT message_hides_event_id_fkey FOREIGN KEY (event_id) REFERENCES chat_events.events(event_id) ON DELETE CASCADE;


--
-- Name: message_reactions_changes message_reactions_changes_event_id_fkey; Type: FK CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.message_reactions_changes
    ADD CONSTRAINT message_reactions_changes_event_id_fkey FOREIGN KEY (event_id) REFERENCES chat_events.events(event_id) ON DELETE CASCADE;


--
-- Name: subscriber_leaves subscriber_leaves_event_id_fkey; Type: FK CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.subscriber_leaves
    ADD CONSTRAINT subscriber_leaves_event_id_fkey FOREIGN KEY (event_id) REFERENCES chat_events.events(event_id) ON DELETE CASCADE;


--
-- Name: subscriber_rejoins subscriber_rejoins_event_id_fkey; Type: FK CONSTRAINT; Schema: chat_events; Owner: -
--

ALTER TABLE ONLY chat_events.subscriber_rejoins
    ADD CONSTRAINT subscriber_rejoins_event_id_fkey FOREIGN KEY (event_id) REFERENCES chat_events.events(event_id) ON DELETE CASCADE;


--
-- Name: chat_message_expiration_changes chat_message_expiration_changes_changed_by_account_id_fkey; Type: FK CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.chat_message_expiration_changes
    ADD CONSTRAINT chat_message_expiration_changes_changed_by_account_id_fkey FOREIGN KEY (changed_by_account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: chat_message_expiration_changes chat_message_expiration_changes_chat_id_fkey; Type: FK CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.chat_message_expiration_changes
    ADD CONSTRAINT chat_message_expiration_changes_chat_id_fkey FOREIGN KEY (chat_id) REFERENCES chats.chats(chat_id) ON DELETE CASCADE;


--
-- Name: chats chats_owner_account_id_fkey; Type: FK CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.chats
    ADD CONSTRAINT chats_owner_account_id_fkey FOREIGN KEY (owner_account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: hidden_messages hidden_messages_account_id_fkey; Type: FK CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.hidden_messages
    ADD CONSTRAINT hidden_messages_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: hidden_messages hidden_messages_message_id_fkey; Type: FK CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.hidden_messages
    ADD CONSTRAINT hidden_messages_message_id_fkey FOREIGN KEY (message_id) REFERENCES chats.messages(message_id) ON DELETE CASCADE;


--
-- Name: latest_message_reactions latest_message_reactions_message_id_fkey; Type: FK CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.latest_message_reactions
    ADD CONSTRAINT latest_message_reactions_message_id_fkey FOREIGN KEY (message_id) REFERENCES chats.messages(message_id) ON DELETE CASCADE;


--
-- Name: member_lists member_lists_chat_id_fkey; Type: FK CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.member_lists
    ADD CONSTRAINT member_lists_chat_id_fkey FOREIGN KEY (chat_id) REFERENCES chats.chats(chat_id) ON DELETE CASCADE;


--
-- Name: members members_account_id_fkey; Type: FK CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.members
    ADD CONSTRAINT members_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: members members_chat_id_fkey; Type: FK CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.members
    ADD CONSTRAINT members_chat_id_fkey FOREIGN KEY (chat_id) REFERENCES chats.chats(chat_id) ON DELETE CASCADE;


--
-- Name: message_idempotency_keys message_idempotency_keys_message_id_fkey; Type: FK CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.message_idempotency_keys
    ADD CONSTRAINT message_idempotency_keys_message_id_fkey FOREIGN KEY (message_id) REFERENCES chats.messages(message_id) ON DELETE CASCADE;


--
-- Name: message_idempotency_keys message_idempotency_keys_oauth_access_token_id_fkey; Type: FK CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.message_idempotency_keys
    ADD CONSTRAINT message_idempotency_keys_oauth_access_token_id_fkey FOREIGN KEY (oauth_access_token_id) REFERENCES public.oauth_access_tokens(id) ON DELETE CASCADE;


--
-- Name: message_media_attachments message_media_attachments_media_attachment_id_fkey; Type: FK CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.message_media_attachments
    ADD CONSTRAINT message_media_attachments_media_attachment_id_fkey FOREIGN KEY (media_attachment_id) REFERENCES public.media_attachments(id) ON DELETE CASCADE;


--
-- Name: message_media_attachments message_media_attachments_message_id_fkey; Type: FK CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.message_media_attachments
    ADD CONSTRAINT message_media_attachments_message_id_fkey FOREIGN KEY (message_id) REFERENCES chats.messages(message_id) ON DELETE CASCADE;


--
-- Name: message_text message_text_message_id_fkey; Type: FK CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.message_text
    ADD CONSTRAINT message_text_message_id_fkey FOREIGN KEY (message_id) REFERENCES chats.messages(message_id) ON DELETE CASCADE;


--
-- Name: messages messages_chat_id_fkey; Type: FK CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.messages
    ADD CONSTRAINT messages_chat_id_fkey FOREIGN KEY (chat_id) REFERENCES chats.chats(chat_id) ON DELETE CASCADE;


--
-- Name: messages messages_created_by_account_id_fkey; Type: FK CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.messages
    ADD CONSTRAINT messages_created_by_account_id_fkey FOREIGN KEY (created_by_account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: reactions reactions_account_id_fkey; Type: FK CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.reactions
    ADD CONSTRAINT reactions_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: reactions reactions_emoji_id_fkey; Type: FK CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.reactions
    ADD CONSTRAINT reactions_emoji_id_fkey FOREIGN KEY (emoji_id) REFERENCES reference.emojis(emoji_id) ON DELETE CASCADE;


--
-- Name: reactions reactions_message_id_fkey; Type: FK CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.reactions
    ADD CONSTRAINT reactions_message_id_fkey FOREIGN KEY (message_id) REFERENCES chats.messages(message_id) ON DELETE CASCADE;


--
-- Name: subscriber_counts subscriber_counts_chat_id_fkey; Type: FK CONSTRAINT; Schema: chats; Owner: -
--

ALTER TABLE ONLY chats.subscriber_counts
    ADD CONSTRAINT subscriber_counts_chat_id_fkey FOREIGN KEY (chat_id) REFERENCES chats.chats(chat_id) ON DELETE CASCADE;


--
-- Name: account_enabled_features account_enabled_features_account_id_fkey; Type: FK CONSTRAINT; Schema: configuration; Owner: -
--

ALTER TABLE ONLY configuration.account_enabled_features
    ADD CONSTRAINT account_enabled_features_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: account_enabled_features account_enabled_features_feature_flag_id_fkey; Type: FK CONSTRAINT; Schema: configuration; Owner: -
--

ALTER TABLE ONLY configuration.account_enabled_features
    ADD CONSTRAINT account_enabled_features_feature_flag_id_fkey FOREIGN KEY (feature_flag_id) REFERENCES configuration.feature_flags(feature_flag_id) ON DELETE CASCADE;


--
-- Name: feature_settings feature_settings_feature_id_fkey; Type: FK CONSTRAINT; Schema: configuration; Owner: -
--

ALTER TABLE ONLY configuration.feature_settings
    ADD CONSTRAINT feature_settings_feature_id_fkey FOREIGN KEY (feature_id) REFERENCES configuration.features(feature_id) ON DELETE CASCADE;


--
-- Name: verification_chat_messages verification_chat_messages_message_id_fkey; Type: FK CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.verification_chat_messages
    ADD CONSTRAINT verification_chat_messages_message_id_fkey FOREIGN KEY (message_id) REFERENCES chats.messages(message_id) ON DELETE CASCADE;


--
-- Name: verification_chat_messages verification_chat_messages_verification_id_fkey; Type: FK CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.verification_chat_messages
    ADD CONSTRAINT verification_chat_messages_verification_id_fkey FOREIGN KEY (verification_id) REFERENCES devices.verifications(verification_id) ON DELETE CASCADE;


--
-- Name: verification_favourites verification_favourites_favourite_id_fkey; Type: FK CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.verification_favourites
    ADD CONSTRAINT verification_favourites_favourite_id_fkey FOREIGN KEY (favourite_id) REFERENCES public.favourites(id) ON DELETE CASCADE;


--
-- Name: verification_favourites verification_favourites_verification_id_fkey; Type: FK CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.verification_favourites
    ADD CONSTRAINT verification_favourites_verification_id_fkey FOREIGN KEY (verification_id) REFERENCES devices.verifications(verification_id) ON DELETE CASCADE;


--
-- Name: verification_registrations verification_registrations_registration_id_fkey; Type: FK CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.verification_registrations
    ADD CONSTRAINT verification_registrations_registration_id_fkey FOREIGN KEY (registration_id) REFERENCES registrations.registrations(registration_id) ON DELETE CASCADE;


--
-- Name: verification_registrations verification_registrations_verification_id_fkey; Type: FK CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.verification_registrations
    ADD CONSTRAINT verification_registrations_verification_id_fkey FOREIGN KEY (verification_id) REFERENCES devices.verifications(verification_id) ON DELETE CASCADE;


--
-- Name: verification_statuses verification_statuses_status_id_fkey; Type: FK CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.verification_statuses
    ADD CONSTRAINT verification_statuses_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: verification_statuses verification_statuses_verification_id_fkey; Type: FK CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.verification_statuses
    ADD CONSTRAINT verification_statuses_verification_id_fkey FOREIGN KEY (verification_id) REFERENCES devices.verifications(verification_id) ON DELETE CASCADE;


--
-- Name: verification_users verification_users_user_id_fkey; Type: FK CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.verification_users
    ADD CONSTRAINT verification_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: verification_users verification_users_verification_id_fkey; Type: FK CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.verification_users
    ADD CONSTRAINT verification_users_verification_id_fkey FOREIGN KEY (verification_id) REFERENCES devices.verifications(verification_id) ON DELETE CASCADE;


--
-- Name: verifications verifications_platform_id_fkey; Type: FK CONSTRAINT; Schema: devices; Owner: -
--

ALTER TABLE ONLY devices.verifications
    ADD CONSTRAINT verifications_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES devices.platforms(platform_id);


--
-- Name: account_feeds account_feeds_account_id_fkey; Type: FK CONSTRAINT; Schema: feeds; Owner: -
--

ALTER TABLE ONLY feeds.account_feeds
    ADD CONSTRAINT account_feeds_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: account_feeds account_feeds_feed_id_fkey; Type: FK CONSTRAINT; Schema: feeds; Owner: -
--

ALTER TABLE ONLY feeds.account_feeds
    ADD CONSTRAINT account_feeds_feed_id_fkey FOREIGN KEY (feed_id) REFERENCES feeds.feeds(feed_id) ON DELETE CASCADE;


--
-- Name: feed_accounts feed_accounts_account_id_fkey; Type: FK CONSTRAINT; Schema: feeds; Owner: -
--

ALTER TABLE ONLY feeds.feed_accounts
    ADD CONSTRAINT feed_accounts_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: feed_accounts feed_accounts_feed_id_fkey; Type: FK CONSTRAINT; Schema: feeds; Owner: -
--

ALTER TABLE ONLY feeds.feed_accounts
    ADD CONSTRAINT feed_accounts_feed_id_fkey FOREIGN KEY (feed_id) REFERENCES feeds.feeds(feed_id) ON DELETE CASCADE;


--
-- Name: feeds feeds_created_by_account_id_fkey; Type: FK CONSTRAINT; Schema: feeds; Owner: -
--

ALTER TABLE ONLY feeds.feeds
    ADD CONSTRAINT feeds_created_by_account_id_fkey FOREIGN KEY (created_by_account_id) REFERENCES public.accounts(id);


--
-- Name: cities cities_region_id_fkey; Type: FK CONSTRAINT; Schema: geography; Owner: -
--

ALTER TABLE ONLY geography.cities
    ADD CONSTRAINT cities_region_id_fkey FOREIGN KEY (region_id) REFERENCES geography.regions(region_id);


--
-- Name: regions regions_country_id_fkey; Type: FK CONSTRAINT; Schema: geography; Owner: -
--

ALTER TABLE ONLY geography.regions
    ADD CONSTRAINT regions_country_id_fkey FOREIGN KEY (country_id) REFERENCES geography.countries(country_id);


--
-- Name: marketing_analytics marketing_analytics_marketing_id_fkey; Type: FK CONSTRAINT; Schema: notifications; Owner: -
--

ALTER TABLE ONLY notifications.marketing_analytics
    ADD CONSTRAINT marketing_analytics_marketing_id_fkey FOREIGN KEY (marketing_id) REFERENCES notifications.marketing(marketing_id);


--
-- Name: marketing_analytics marketing_analytics_oauth_access_token_id_fkey; Type: FK CONSTRAINT; Schema: notifications; Owner: -
--

ALTER TABLE ONLY notifications.marketing_analytics
    ADD CONSTRAINT marketing_analytics_oauth_access_token_id_fkey FOREIGN KEY (oauth_access_token_id) REFERENCES public.oauth_access_tokens(id);


--
-- Name: marketing marketing_status_id_fkey; Type: FK CONSTRAINT; Schema: notifications; Owner: -
--

ALTER TABLE ONLY notifications.marketing
    ADD CONSTRAINT marketing_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: integrity_credentials integrity_credentials_oauth_access_token_id_fkey; Type: FK CONSTRAINT; Schema: oauth_access_tokens; Owner: -
--

ALTER TABLE ONLY oauth_access_tokens.integrity_credentials
    ADD CONSTRAINT integrity_credentials_oauth_access_token_id_fkey FOREIGN KEY (oauth_access_token_id) REFERENCES public.oauth_access_tokens(id) ON DELETE CASCADE;


--
-- Name: integrity_credentials integrity_credentials_verification_id_fkey; Type: FK CONSTRAINT; Schema: oauth_access_tokens; Owner: -
--

ALTER TABLE ONLY oauth_access_tokens.integrity_credentials
    ADD CONSTRAINT integrity_credentials_verification_id_fkey FOREIGN KEY (verification_id) REFERENCES devices.verifications(verification_id) ON DELETE CASCADE;


--
-- Name: webauthn_credentials webauthn_credentials_oauth_access_token_id_fkey; Type: FK CONSTRAINT; Schema: oauth_access_tokens; Owner: -
--

ALTER TABLE ONLY oauth_access_tokens.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_oauth_access_token_id_fkey FOREIGN KEY (oauth_access_token_id) REFERENCES public.oauth_access_tokens(id) ON DELETE CASCADE;


--
-- Name: webauthn_credentials webauthn_credentials_webauthn_credential_id_fkey; Type: FK CONSTRAINT; Schema: oauth_access_tokens; Owner: -
--

ALTER TABLE ONLY oauth_access_tokens.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_webauthn_credential_id_fkey FOREIGN KEY (webauthn_credential_id) REFERENCES public.webauthn_credentials(id) ON DELETE CASCADE;


--
-- Name: options options_poll_id_fkey; Type: FK CONSTRAINT; Schema: polls; Owner: -
--

ALTER TABLE ONLY polls.options
    ADD CONSTRAINT options_poll_id_fkey FOREIGN KEY (poll_id) REFERENCES polls.polls(poll_id) ON DELETE CASCADE;


--
-- Name: status_polls status_polls_poll_id_fkey; Type: FK CONSTRAINT; Schema: polls; Owner: -
--

ALTER TABLE ONLY polls.status_polls
    ADD CONSTRAINT status_polls_poll_id_fkey FOREIGN KEY (poll_id) REFERENCES polls.polls(poll_id) ON DELETE CASCADE;


--
-- Name: status_polls status_polls_status_id_fkey; Type: FK CONSTRAINT; Schema: polls; Owner: -
--

ALTER TABLE ONLY polls.status_polls
    ADD CONSTRAINT status_polls_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: votes votes_account_id_fkey; Type: FK CONSTRAINT; Schema: polls; Owner: -
--

ALTER TABLE ONLY polls.votes
    ADD CONSTRAINT votes_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: votes votes_poll_id_option_number_fkey; Type: FK CONSTRAINT; Schema: polls; Owner: -
--

ALTER TABLE ONLY polls.votes
    ADD CONSTRAINT votes_poll_id_option_number_fkey FOREIGN KEY (poll_id, option_number) REFERENCES polls.options(poll_id, option_number) ON DELETE CASCADE;


--
-- Name: web_settings fk_11910667b2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_settings
    ADD CONSTRAINT fk_11910667b2 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: account_domain_blocks fk_206c6029bd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_domain_blocks
    ADD CONSTRAINT fk_206c6029bd FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: conversation_mutes fk_225b4212bb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_mutes
    ADD CONSTRAINT fk_225b4212bb FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: statuses_tags fk_3081861e21; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statuses_tags
    ADD CONSTRAINT fk_3081861e21 FOREIGN KEY (tag_id) REFERENCES public.tags(id) ON DELETE CASCADE;


--
-- Name: follows fk_32ed1b5560; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follows
    ADD CONSTRAINT fk_32ed1b5560 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: oauth_access_grants fk_34d54b0a33; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT fk_34d54b0a33 FOREIGN KEY (application_id) REFERENCES public.oauth_applications(id) ON DELETE CASCADE;


--
-- Name: blocks fk_4269e03e65; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocks
    ADD CONSTRAINT fk_4269e03e65 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: reports fk_4b81f7522c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT fk_4b81f7522c FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: users fk_50500f500d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_50500f500d FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: favourites fk_5eb6c2b873; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favourites
    ADD CONSTRAINT fk_5eb6c2b873 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: oauth_access_grants fk_63b044929b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_grants
    ADD CONSTRAINT fk_63b044929b FOREIGN KEY (resource_owner_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: imports fk_6db1b6e408; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.imports
    ADD CONSTRAINT fk_6db1b6e408 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: follows fk_745ca29eac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follows
    ADD CONSTRAINT fk_745ca29eac FOREIGN KEY (target_account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: follow_requests fk_76d644b0e7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follow_requests
    ADD CONSTRAINT fk_76d644b0e7 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: follow_requests fk_9291ec025d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follow_requests
    ADD CONSTRAINT fk_9291ec025d FOREIGN KEY (target_account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: blocks fk_9571bfabc1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.blocks
    ADD CONSTRAINT fk_9571bfabc1 FOREIGN KEY (target_account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: session_activations fk_957e5bda89; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_activations
    ADD CONSTRAINT fk_957e5bda89 FOREIGN KEY (access_token_id) REFERENCES public.oauth_access_tokens(id) ON DELETE CASCADE;


--
-- Name: media_attachments fk_96dd81e81b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_attachments
    ADD CONSTRAINT fk_96dd81e81b FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE SET NULL;


--
-- Name: mentions fk_970d43f9d1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mentions
    ADD CONSTRAINT fk_970d43f9d1 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: statuses fk_9bda1543f7; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statuses
    ADD CONSTRAINT fk_9bda1543f7 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: oauth_applications fk_b0988c7c0a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_applications
    ADD CONSTRAINT fk_b0988c7c0a FOREIGN KEY (owner_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: favourites fk_b0e856845e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favourites
    ADD CONSTRAINT fk_b0e856845e FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: mutes fk_b8d8daf315; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mutes
    ADD CONSTRAINT fk_b8d8daf315 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: reports fk_bca45b75fd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT fk_bca45b75fd FOREIGN KEY (action_taken_by_account_id) REFERENCES public.accounts(id) ON DELETE SET NULL;


--
-- Name: identities fk_bea040f377; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.identities
    ADD CONSTRAINT fk_bea040f377 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: statuses fk_c7fa917661; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statuses
    ADD CONSTRAINT fk_c7fa917661 FOREIGN KEY (in_reply_to_account_id) REFERENCES public.accounts(id) ON DELETE SET NULL;


--
-- Name: status_pins fk_d4cb435b62; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_pins
    ADD CONSTRAINT fk_d4cb435b62 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: session_activations fk_e5fda67334; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.session_activations
    ADD CONSTRAINT fk_e5fda67334 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: oauth_access_tokens fk_e84df68546; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT fk_e84df68546 FOREIGN KEY (resource_owner_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: reports fk_eb37af34f0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT fk_eb37af34f0 FOREIGN KEY (target_account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: mutes fk_eecff219ea; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mutes
    ADD CONSTRAINT fk_eecff219ea FOREIGN KEY (target_account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: oauth_access_tokens fk_f5fc4c1ee3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.oauth_access_tokens
    ADD CONSTRAINT fk_f5fc4c1ee3 FOREIGN KEY (application_id) REFERENCES public.oauth_applications(id) ON DELETE CASCADE;


--
-- Name: backups fk_rails_096669d221; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.backups
    ADD CONSTRAINT fk_rails_096669d221 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: ads fk_rails_1110cede51; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ads
    ADD CONSTRAINT fk_rails_1110cede51 FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: bookmarks fk_rails_11207ffcfd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT fk_rails_11207ffcfd FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: group_deletion_requests fk_rails_121db9db92; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_deletion_requests
    ADD CONSTRAINT fk_rails_121db9db92 FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: account_conversations fk_rails_1491654f9f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_conversations
    ADD CONSTRAINT fk_rails_1491654f9f FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE;


--
-- Name: featured_tags fk_rails_174efcf15f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.featured_tags
    ADD CONSTRAINT fk_rails_174efcf15f FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: canonical_email_blocks fk_rails_1ecb262096; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.canonical_email_blocks
    ADD CONSTRAINT fk_rails_1ecb262096 FOREIGN KEY (reference_account_id) REFERENCES public.accounts(id);


--
-- Name: account_stats fk_rails_215bb31ff1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_stats
    ADD CONSTRAINT fk_rails_215bb31ff1 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: accounts fk_rails_2320833084; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT fk_rails_2320833084 FOREIGN KEY (moved_to_account_id) REFERENCES public.accounts(id) ON DELETE SET NULL;


--
-- Name: featured_tags fk_rails_23a9055c7c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.featured_tags
    ADD CONSTRAINT fk_rails_23a9055c7c FOREIGN KEY (tag_id) REFERENCES public.tags(id) ON DELETE CASCADE;


--
-- Name: scheduled_statuses fk_rails_23bd9018f9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scheduled_statuses
    ADD CONSTRAINT fk_rails_23bd9018f9 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: statuses fk_rails_256483a9ab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statuses
    ADD CONSTRAINT fk_rails_256483a9ab FOREIGN KEY (reblog_of_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: account_notes fk_rails_2801b48f1a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_notes
    ADD CONSTRAINT fk_rails_2801b48f1a FOREIGN KEY (target_account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: statuses fk_rails_30016aba2f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statuses
    ADD CONSTRAINT fk_rails_30016aba2f FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: media_attachments fk_rails_31fc5aeef1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_attachments
    ADD CONSTRAINT fk_rails_31fc5aeef1 FOREIGN KEY (scheduled_status_id) REFERENCES public.scheduled_statuses(id) ON DELETE SET NULL;


--
-- Name: user_invite_requests fk_rails_3773f15361; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_invite_requests
    ADD CONSTRAINT fk_rails_3773f15361 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: lists fk_rails_3853b78dac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lists
    ADD CONSTRAINT fk_rails_3853b78dac FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: devices fk_rails_393f74df68; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT fk_rails_393f74df68 FOREIGN KEY (access_token_id) REFERENCES public.oauth_access_tokens(id) ON DELETE CASCADE;


--
-- Name: media_attachments fk_rails_3ec0cfdd70; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.media_attachments
    ADD CONSTRAINT fk_rails_3ec0cfdd70 FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE SET NULL;


--
-- Name: account_moderation_notes fk_rails_3f8b75089b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_moderation_notes
    ADD CONSTRAINT fk_rails_3f8b75089b FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: email_domain_blocks fk_rails_408efe0a15; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_domain_blocks
    ADD CONSTRAINT fk_rails_408efe0a15 FOREIGN KEY (parent_id) REFERENCES public.email_domain_blocks(id) ON DELETE CASCADE;


--
-- Name: list_accounts fk_rails_40f9cc29f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.list_accounts
    ADD CONSTRAINT fk_rails_40f9cc29f1 FOREIGN KEY (follow_id) REFERENCES public.follows(id) ON DELETE CASCADE;


--
-- Name: account_deletion_requests fk_rails_45bf2626b9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_deletion_requests
    ADD CONSTRAINT fk_rails_45bf2626b9 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: group_account_blocks fk_rails_4a013b0aca; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_account_blocks
    ADD CONSTRAINT fk_rails_4a013b0aca FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: status_stats fk_rails_4a247aac42; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_stats
    ADD CONSTRAINT fk_rails_4a247aac42 FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: reports fk_rails_4e7a498fb4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT fk_rails_4e7a498fb4 FOREIGN KEY (assigned_account_id) REFERENCES public.accounts(id) ON DELETE SET NULL;


--
-- Name: account_notes fk_rails_4ee4503c69; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_notes
    ADD CONSTRAINT fk_rails_4ee4503c69 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: group_stats fk_rails_50f7bc8ac4; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_stats
    ADD CONSTRAINT fk_rails_50f7bc8ac4 FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: mentions fk_rails_59edbe2887; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mentions
    ADD CONSTRAINT fk_rails_59edbe2887 FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: conversation_mutes fk_rails_5ab139311f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversation_mutes
    ADD CONSTRAINT fk_rails_5ab139311f FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE;


--
-- Name: group_suggestions fk_rails_5b50f5b6fa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_suggestions
    ADD CONSTRAINT fk_rails_5b50f5b6fa FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: status_pins fk_rails_65c05552f1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_pins
    ADD CONSTRAINT fk_rails_65c05552f1 FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: account_identity_proofs fk_rails_6a219ca385; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_identity_proofs
    ADD CONSTRAINT fk_rails_6a219ca385 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: account_conversations fk_rails_6f5278b6e9; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_conversations
    ADD CONSTRAINT fk_rails_6f5278b6e9 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: announcement_reactions fk_rails_7444ad831f; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcement_reactions
    ADD CONSTRAINT fk_rails_7444ad831f FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: web_push_subscriptions fk_rails_751a9f390b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_push_subscriptions
    ADD CONSTRAINT fk_rails_751a9f390b FOREIGN KEY (access_token_id) REFERENCES public.oauth_access_tokens(id) ON DELETE CASCADE;


--
-- Name: users fk_rails_761493275a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_761493275a FOREIGN KEY (policy_id) REFERENCES public.policies(id) ON DELETE SET NULL;


--
-- Name: report_notes fk_rails_7fa83a61eb; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_notes
    ADD CONSTRAINT fk_rails_7fa83a61eb FOREIGN KEY (report_id) REFERENCES public.reports(id) ON DELETE CASCADE;


--
-- Name: list_accounts fk_rails_85fee9d6ab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.list_accounts
    ADD CONSTRAINT fk_rails_85fee9d6ab FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: custom_filters fk_rails_8b8d786993; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_filters
    ADD CONSTRAINT fk_rails_8b8d786993 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: users fk_rails_8fb2a43e88; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_8fb2a43e88 FOREIGN KEY (invite_id) REFERENCES public.invites(id) ON DELETE SET NULL;


--
-- Name: statuses fk_rails_94a6f70399; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statuses
    ADD CONSTRAINT fk_rails_94a6f70399 FOREIGN KEY (in_reply_to_id) REFERENCES public.statuses(id) ON DELETE SET NULL;


--
-- Name: one_time_challenges fk_rails_9886dcf8b6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.one_time_challenges
    ADD CONSTRAINT fk_rails_9886dcf8b6 FOREIGN KEY (webauthn_credential_id) REFERENCES public.webauthn_credentials(id) ON DELETE CASCADE;


--
-- Name: group_membership_requests fk_rails_9a1561c974; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_membership_requests
    ADD CONSTRAINT fk_rails_9a1561c974 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: one_time_challenges fk_rails_9aac27c603; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.one_time_challenges
    ADD CONSTRAINT fk_rails_9aac27c603 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: announcement_mutes fk_rails_9c99f8e835; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcement_mutes
    ADD CONSTRAINT fk_rails_9c99f8e835 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: bookmarks fk_rails_9f6ac182a6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bookmarks
    ADD CONSTRAINT fk_rails_9f6ac182a6 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: announcement_reactions fk_rails_a1226eaa5c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcement_reactions
    ADD CONSTRAINT fk_rails_a1226eaa5c FOREIGN KEY (announcement_id) REFERENCES public.announcements(id) ON DELETE CASCADE;


--
-- Name: account_pins fk_rails_a176e26c37; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_pins
    ADD CONSTRAINT fk_rails_a176e26c37 FOREIGN KEY (target_account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: encrypted_messages fk_rails_a42ad0f8d5; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encrypted_messages
    ADD CONSTRAINT fk_rails_a42ad0f8d5 FOREIGN KEY (from_account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: webauthn_credentials fk_rails_a4355aef77; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webauthn_credentials
    ADD CONSTRAINT fk_rails_a4355aef77 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: account_warnings fk_rails_a65a1bf71b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_warnings
    ADD CONSTRAINT fk_rails_a65a1bf71b FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE SET NULL;


--
-- Name: markers fk_rails_a7009bc2b6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.markers
    ADD CONSTRAINT fk_rails_a7009bc2b6 FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: admin_action_logs fk_rails_a7667297fa; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_action_logs
    ADD CONSTRAINT fk_rails_a7667297fa FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: devices fk_rails_a796b75798; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.devices
    ADD CONSTRAINT fk_rails_a796b75798 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: account_warnings fk_rails_a7ebbb1e37; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_warnings
    ADD CONSTRAINT fk_rails_a7ebbb1e37 FOREIGN KEY (target_account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: encrypted_messages fk_rails_a83e4df7ae; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.encrypted_messages
    ADD CONSTRAINT fk_rails_a83e4df7ae FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;


--
-- Name: web_push_subscriptions fk_rails_b006f28dac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_push_subscriptions
    ADD CONSTRAINT fk_rails_b006f28dac FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: announcement_reactions fk_rails_b742c91c0e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcement_reactions
    ADD CONSTRAINT fk_rails_b742c91c0e FOREIGN KEY (custom_emoji_id) REFERENCES public.custom_emojis(id) ON DELETE CASCADE;


--
-- Name: group_membership_requests fk_rails_c20da253a3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_membership_requests
    ADD CONSTRAINT fk_rails_c20da253a3 FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: account_migrations fk_rails_c9f701caaf; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_migrations
    ADD CONSTRAINT fk_rails_c9f701caaf FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: report_notes fk_rails_cae66353f3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_notes
    ADD CONSTRAINT fk_rails_cae66353f3 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: group_memberships fk_rails_d05778f88b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_memberships
    ADD CONSTRAINT fk_rails_d05778f88b FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: one_time_keys fk_rails_d3edd8c878; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.one_time_keys
    ADD CONSTRAINT fk_rails_d3edd8c878 FOREIGN KEY (device_id) REFERENCES public.devices(id) ON DELETE CASCADE;


--
-- Name: account_pins fk_rails_d44979e5dd; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_pins
    ADD CONSTRAINT fk_rails_d44979e5dd FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: account_migrations fk_rails_d9a8dad070; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_migrations
    ADD CONSTRAINT fk_rails_d9a8dad070 FOREIGN KEY (target_account_id) REFERENCES public.accounts(id) ON DELETE SET NULL;


--
-- Name: account_moderation_notes fk_rails_dd62ed5ac3; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_moderation_notes
    ADD CONSTRAINT fk_rails_dd62ed5ac3 FOREIGN KEY (target_account_id) REFERENCES public.accounts(id);


--
-- Name: statuses_tags fk_rails_df0fe11427; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.statuses_tags
    ADD CONSTRAINT fk_rails_df0fe11427 FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: follow_recommendation_suppressions fk_rails_dfb9a1dbe2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.follow_recommendation_suppressions
    ADD CONSTRAINT fk_rails_dfb9a1dbe2 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: group_memberships fk_rails_e1a000e53a; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_memberships
    ADD CONSTRAINT fk_rails_e1a000e53a FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: announcement_mutes fk_rails_e35401adf1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.announcement_mutes
    ADD CONSTRAINT fk_rails_e35401adf1 FOREIGN KEY (announcement_id) REFERENCES public.announcements(id) ON DELETE CASCADE;


--
-- Name: list_accounts fk_rails_e54e356c88; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.list_accounts
    ADD CONSTRAINT fk_rails_e54e356c88 FOREIGN KEY (list_id) REFERENCES public.lists(id) ON DELETE CASCADE;


--
-- Name: users fk_rails_ecc9536e7c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_rails_ecc9536e7c FOREIGN KEY (created_by_application_id) REFERENCES public.oauth_applications(id) ON DELETE SET NULL;


--
-- Name: group_account_blocks fk_rails_eea5771e3d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_account_blocks
    ADD CONSTRAINT fk_rails_eea5771e3d FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: tombstones fk_rails_f95b861449; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tombstones
    ADD CONSTRAINT fk_rails_f95b861449 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: account_aliases fk_rails_fc91575d08; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.account_aliases
    ADD CONSTRAINT fk_rails_fc91575d08 FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: invites fk_rails_ff69dbb2ac; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.invites
    ADD CONSTRAINT fk_rails_ff69dbb2ac FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: group_mutes group_mutes_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_mutes
    ADD CONSTRAINT group_mutes_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: group_mutes group_mutes_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_mutes
    ADD CONSTRAINT group_mutes_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id);


--
-- Name: group_suggestion_deletes group_suggestion_deletes_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_suggestion_deletes
    ADD CONSTRAINT group_suggestion_deletes_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: group_suggestion_deletes group_suggestion_deletes_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_suggestion_deletes
    ADD CONSTRAINT group_suggestion_deletes_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: group_tags group_tags_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_tags
    ADD CONSTRAINT group_tags_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: group_tags group_tags_tag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.group_tags
    ADD CONSTRAINT group_tags_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES public.tags(id) ON DELETE CASCADE;


--
-- Name: groups groups_owner_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.groups
    ADD CONSTRAINT groups_owner_account_id_fkey FOREIGN KEY (owner_account_id) REFERENCES public.accounts(id);


--
-- Name: links_statuses links_statuses_link_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.links_statuses
    ADD CONSTRAINT links_statuses_link_id_fkey FOREIGN KEY (link_id) REFERENCES public.links(id) ON DELETE CASCADE;


--
-- Name: links_statuses links_statuses_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.links_statuses
    ADD CONSTRAINT links_statuses_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: notifications notifications_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.notifications
    ADD CONSTRAINT notifications_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id);


--
-- Name: notifications notifications_from_account_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE public.notifications
    ADD CONSTRAINT notifications_from_account_id_fkey FOREIGN KEY (from_account_id) REFERENCES public.accounts(id);


--
-- Name: reports reports_external_ad_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_external_ad_id_fkey FOREIGN KEY (external_ad_id) REFERENCES public.external_ads(external_ad_id) ON DELETE CASCADE;


--
-- Name: users users_sign_up_city_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_sign_up_city_id_fkey FOREIGN KEY (sign_up_city_id) REFERENCES geography.cities(city_id);


--
-- Name: account_suppressions account_suppressions_account_id_fkey; Type: FK CONSTRAINT; Schema: recommendations; Owner: -
--

ALTER TABLE ONLY recommendations.account_suppressions
    ADD CONSTRAINT account_suppressions_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: account_suppressions account_suppressions_status_id_fkey; Type: FK CONSTRAINT; Schema: recommendations; Owner: -
--

ALTER TABLE ONLY recommendations.account_suppressions
    ADD CONSTRAINT account_suppressions_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: account_suppressions account_suppressions_target_account_id_fkey; Type: FK CONSTRAINT; Schema: recommendations; Owner: -
--

ALTER TABLE ONLY recommendations.account_suppressions
    ADD CONSTRAINT account_suppressions_target_account_id_fkey FOREIGN KEY (target_account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: follows follows_account_id_fkey; Type: FK CONSTRAINT; Schema: recommendations; Owner: -
--

ALTER TABLE ONLY recommendations.follows
    ADD CONSTRAINT follows_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: group_suppressions group_suppressions_account_id_fkey; Type: FK CONSTRAINT; Schema: recommendations; Owner: -
--

ALTER TABLE ONLY recommendations.group_suppressions
    ADD CONSTRAINT group_suppressions_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: group_suppressions group_suppressions_group_id_fkey; Type: FK CONSTRAINT; Schema: recommendations; Owner: -
--

ALTER TABLE ONLY recommendations.group_suppressions
    ADD CONSTRAINT group_suppressions_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: group_suppressions group_suppressions_status_id_fkey; Type: FK CONSTRAINT; Schema: recommendations; Owner: -
--

ALTER TABLE ONLY recommendations.group_suppressions
    ADD CONSTRAINT group_suppressions_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: statuses statuses_account_id_fkey; Type: FK CONSTRAINT; Schema: recommendations; Owner: -
--

ALTER TABLE ONLY recommendations.statuses
    ADD CONSTRAINT statuses_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: one_time_challenges one_time_challenges_one_time_challenge_id_fkey; Type: FK CONSTRAINT; Schema: registrations; Owner: -
--

ALTER TABLE ONLY registrations.one_time_challenges
    ADD CONSTRAINT one_time_challenges_one_time_challenge_id_fkey FOREIGN KEY (one_time_challenge_id) REFERENCES public.one_time_challenges(id) ON DELETE CASCADE;


--
-- Name: one_time_challenges one_time_challenges_registration_id_fkey; Type: FK CONSTRAINT; Schema: registrations; Owner: -
--

ALTER TABLE ONLY registrations.one_time_challenges
    ADD CONSTRAINT one_time_challenges_registration_id_fkey FOREIGN KEY (registration_id) REFERENCES registrations.registrations(registration_id) ON DELETE CASCADE;


--
-- Name: registrations registrations_platform_id_fkey; Type: FK CONSTRAINT; Schema: registrations; Owner: -
--

ALTER TABLE ONLY registrations.registrations
    ADD CONSTRAINT registrations_platform_id_fkey FOREIGN KEY (platform_id) REFERENCES devices.platforms(platform_id);


--
-- Name: webauthn_credentials webauthn_credentials_registration_id_fkey; Type: FK CONSTRAINT; Schema: registrations; Owner: -
--

ALTER TABLE ONLY registrations.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_registration_id_fkey FOREIGN KEY (registration_id) REFERENCES registrations.registrations(registration_id) ON DELETE CASCADE;


--
-- Name: webauthn_credentials webauthn_credentials_webauthn_credential_id_fkey; Type: FK CONSTRAINT; Schema: registrations; Owner: -
--

ALTER TABLE ONLY registrations.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_webauthn_credential_id_fkey FOREIGN KEY (webauthn_credential_id) REFERENCES public.webauthn_credentials(id) ON DELETE CASCADE;


--
-- Name: account_followers account_followers_account_id_fkey; Type: FK CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.account_followers
    ADD CONSTRAINT account_followers_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: account_following account_following_account_id_fkey; Type: FK CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.account_following
    ADD CONSTRAINT account_following_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: account_statuses account_statuses_account_id_fkey; Type: FK CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.account_statuses
    ADD CONSTRAINT account_statuses_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: status_view_counts fk_statuses; Type: FK CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.status_view_counts
    ADD CONSTRAINT fk_statuses FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: poll_options poll_options_poll_id_option_number_fkey; Type: FK CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.poll_options
    ADD CONSTRAINT poll_options_poll_id_option_number_fkey FOREIGN KEY (poll_id, option_number) REFERENCES polls.options(poll_id, option_number) ON DELETE CASCADE;


--
-- Name: polls polls_poll_id_fkey; Type: FK CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.polls
    ADD CONSTRAINT polls_poll_id_fkey FOREIGN KEY (poll_id) REFERENCES polls.polls(poll_id) ON DELETE CASCADE;


--
-- Name: reply_status_controversial_scores reply_status_controversial_scores_reply_to_status_id_fkey; Type: FK CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.reply_status_controversial_scores
    ADD CONSTRAINT reply_status_controversial_scores_reply_to_status_id_fkey FOREIGN KEY (reply_to_status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: reply_status_controversial_scores reply_status_controversial_scores_status_id_fkey; Type: FK CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.reply_status_controversial_scores
    ADD CONSTRAINT reply_status_controversial_scores_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: reply_status_trending_scores reply_status_trending_scores_reply_to_status_id_fkey; Type: FK CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.reply_status_trending_scores
    ADD CONSTRAINT reply_status_trending_scores_reply_to_status_id_fkey FOREIGN KEY (reply_to_status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: reply_status_trending_scores reply_status_trending_scores_status_id_fkey; Type: FK CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.reply_status_trending_scores
    ADD CONSTRAINT reply_status_trending_scores_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: status_engagement status_engagement_status_id_fkey; Type: FK CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.status_engagement
    ADD CONSTRAINT status_engagement_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: status_favourites status_favourites_status_id_fkey; Type: FK CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.status_favourites
    ADD CONSTRAINT status_favourites_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: status_reblogs status_reblogs_status_id_fkey; Type: FK CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.status_reblogs
    ADD CONSTRAINT status_reblogs_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: status_replies status_replies_status_id_fkey; Type: FK CONSTRAINT; Schema: statistics; Owner: -
--

ALTER TABLE ONLY statistics.status_replies
    ADD CONSTRAINT status_replies_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: analysis analysis_status_id_fkey; Type: FK CONSTRAINT; Schema: statuses; Owner: -
--

ALTER TABLE ONLY statuses.analysis
    ADD CONSTRAINT analysis_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: moderation_results moderation_results_status_id_fkey; Type: FK CONSTRAINT; Schema: statuses; Owner: -
--

ALTER TABLE ONLY statuses.moderation_results
    ADD CONSTRAINT moderation_results_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.statuses(id);


--
-- Name: excluded_groups excluded_groups_group_id_fkey; Type: FK CONSTRAINT; Schema: trending_groups; Owner: -
--

ALTER TABLE ONLY trending_groups.excluded_groups
    ADD CONSTRAINT excluded_groups_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE CASCADE;


--
-- Name: excluded_statuses excluded_statuses_status_id_fkey; Type: FK CONSTRAINT; Schema: trending_statuses; Owner: -
--

ALTER TABLE ONLY trending_statuses.excluded_statuses
    ADD CONSTRAINT excluded_statuses_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: accounts accounts_account_id_fkey; Type: FK CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.accounts
    ADD CONSTRAINT accounts_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: channel_accounts channel_accounts_account_id_fkey; Type: FK CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.channel_accounts
    ADD CONSTRAINT channel_accounts_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: channel_accounts channel_accounts_channel_id_fkey; Type: FK CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.channel_accounts
    ADD CONSTRAINT channel_accounts_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES tv.channels(channel_id) ON DELETE CASCADE;


--
-- Name: device_sessions device_sessions_oauth_access_token_id_fkey; Type: FK CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.device_sessions
    ADD CONSTRAINT device_sessions_oauth_access_token_id_fkey FOREIGN KEY (oauth_access_token_id) REFERENCES public.oauth_access_tokens(id) ON DELETE CASCADE;


--
-- Name: program_statuses program_statuses_channel_id_start_time_fkey; Type: FK CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.program_statuses
    ADD CONSTRAINT program_statuses_channel_id_start_time_fkey FOREIGN KEY (channel_id, start_time) REFERENCES tv.programs(channel_id, start_time) ON DELETE CASCADE;


--
-- Name: program_statuses program_statuses_status_id_fkey; Type: FK CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.program_statuses
    ADD CONSTRAINT program_statuses_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: programs programs_channel_id_fkey; Type: FK CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.programs
    ADD CONSTRAINT programs_channel_id_fkey FOREIGN KEY (channel_id) REFERENCES tv.channels(channel_id) ON DELETE CASCADE;


--
-- Name: reminders reminders_account_id_fkey; Type: FK CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.reminders
    ADD CONSTRAINT reminders_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id) ON DELETE CASCADE;


--
-- Name: reminders reminders_channel_id_start_time_fkey; Type: FK CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.reminders
    ADD CONSTRAINT reminders_channel_id_start_time_fkey FOREIGN KEY (channel_id, start_time) REFERENCES tv.programs(channel_id, start_time) ON DELETE CASCADE;


--
-- Name: statuses statuses_status_id_fkey; Type: FK CONSTRAINT; Schema: tv; Owner: -
--

ALTER TABLE ONLY tv.statuses
    ADD CONSTRAINT statuses_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.statuses(id) ON DELETE CASCADE;


--
-- Name: base_emails base_emails_user_id_fkey; Type: FK CONSTRAINT; Schema: users; Owner: -
--

ALTER TABLE ONLY users.base_emails
    ADD CONSTRAINT base_emails_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: current_information current_information_current_city_id_fkey; Type: FK CONSTRAINT; Schema: users; Owner: -
--

ALTER TABLE ONLY users.current_information
    ADD CONSTRAINT current_information_current_city_id_fkey FOREIGN KEY (current_city_id) REFERENCES geography.cities(city_id);


--
-- Name: current_information current_information_user_id_fkey; Type: FK CONSTRAINT; Schema: users; Owner: -
--

ALTER TABLE ONLY users.current_information
    ADD CONSTRAINT current_information_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: one_time_challenges one_time_challenges_one_time_challenge_id_fkey; Type: FK CONSTRAINT; Schema: users; Owner: -
--

ALTER TABLE ONLY users.one_time_challenges
    ADD CONSTRAINT one_time_challenges_one_time_challenge_id_fkey FOREIGN KEY (one_time_challenge_id) REFERENCES public.one_time_challenges(id) ON DELETE CASCADE;


--
-- Name: one_time_challenges one_time_challenges_user_id_fkey; Type: FK CONSTRAINT; Schema: users; Owner: -
--

ALTER TABLE ONLY users.one_time_challenges
    ADD CONSTRAINT one_time_challenges_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: password_histories password_histories_user_id_fkey; Type: FK CONSTRAINT; Schema: users; Owner: -
--

ALTER TABLE ONLY users.password_histories
    ADD CONSTRAINT password_histories_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: sms_reverification_required sms_reverification_required_user_id_fkey; Type: FK CONSTRAINT; Schema: users; Owner: -
--

ALTER TABLE ONLY users.sms_reverification_required
    ADD CONSTRAINT sms_reverification_required_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20160220174730'),
('20160220211917'),
('20160221003140'),
('20160221003621'),
('20160222122600'),
('20160222143943'),
('20160223162837'),
('20160223164502'),
('20160223165723'),
('20160223165855'),
('20160223171800'),
('20160224223247'),
('20160227230233'),
('20160305115639'),
('20160306172223'),
('20160312193225'),
('20160314164231'),
('20160316103650'),
('20160322193748'),
('20160325130944'),
('20160826155805'),
('20160905150353'),
('20160919221059'),
('20160920003904'),
('20160926213048'),
('20161003142332'),
('20161003145426'),
('20161006213403'),
('20161009120834'),
('20161027172456'),
('20161104173623'),
('20161105130633'),
('20161116162355'),
('20161119211120'),
('20161122163057'),
('20161123093447'),
('20161128103007'),
('20161130142058'),
('20161130185319'),
('20161202132159'),
('20161203164520'),
('20161205214545'),
('20161221152630'),
('20161222201034'),
('20161222204147'),
('20170105224407'),
('20170109120109'),
('20170112154826'),
('20170114194937'),
('20170114203041'),
('20170119214911'),
('20170123162658'),
('20170123203248'),
('20170125145934'),
('20170127165745'),
('20170205175257'),
('20170209184350'),
('20170214110202'),
('20170217012631'),
('20170301222600'),
('20170303212857'),
('20170304202101'),
('20170317193015'),
('20170318214217'),
('20170322021028'),
('20170322143850'),
('20170322162804'),
('20170330021336'),
('20170330163835'),
('20170330164118'),
('20170403172249'),
('20170405112956'),
('20170406215816'),
('20170409170753'),
('20170414080609'),
('20170414132105'),
('20170418160728'),
('20170423005413'),
('20170424003227'),
('20170424112722'),
('20170425131920'),
('20170425202925'),
('20170427011934'),
('20170506235850'),
('20170507000211'),
('20170507141759'),
('20170508230434'),
('20170516072309'),
('20170520145338'),
('20170601210557'),
('20170604144747'),
('20170606113804'),
('20170609145826'),
('20170610000000'),
('20170623152212'),
('20170624134742'),
('20170625140443'),
('20170711225116'),
('20170713112503'),
('20170713175513'),
('20170713190709'),
('20170714184731'),
('20170716191202'),
('20170718211102'),
('20170720000000'),
('20170823162448'),
('20170824103029'),
('20170829215220'),
('20170901141119'),
('20170901142658'),
('20170905044538'),
('20170905165803'),
('20170913000752'),
('20170917153509'),
('20170918125918'),
('20170920024819'),
('20170920032311'),
('20170924022025'),
('20170927215609'),
('20170928082043'),
('20171005102658'),
('20171005171936'),
('20171006142024'),
('20171010023049'),
('20171010025614'),
('20171020084748'),
('20171028221157'),
('20171107143332'),
('20171107143624'),
('20171109012327'),
('20171114080328'),
('20171114231651'),
('20171116161857'),
('20171118012443'),
('20171119172437'),
('20171122120436'),
('20171125024930'),
('20171125031751'),
('20171125185353'),
('20171125190735'),
('20171129172043'),
('20171130000000'),
('20171201000000'),
('20171212195226'),
('20171226094803'),
('20180106000232'),
('20180109143959'),
('20180204034416'),
('20180206000000'),
('20180211015820'),
('20180304013859'),
('20180310000000'),
('20180402031200'),
('20180402040909'),
('20180410204633'),
('20180416210259'),
('20180419235016'),
('20180506221944'),
('20180510214435'),
('20180510230049'),
('20180514130000'),
('20180514140000'),
('20180528141303'),
('20180608213548'),
('20180609104432'),
('20180615122121'),
('20180616192031'),
('20180617162849'),
('20180628181026'),
('20180707154237'),
('20180711152640'),
('20180808175627'),
('20180812123222'),
('20180812162710'),
('20180812173710'),
('20180813113448'),
('20180814171349'),
('20180820232245'),
('20180831171112'),
('20180929222014'),
('20181007025445'),
('20181010141500'),
('20181017170937'),
('20181018205649'),
('20181024224956'),
('20181026034033'),
('20181116165755'),
('20181116173541'),
('20181116184611'),
('20181127130500'),
('20181127165847'),
('20181203003808'),
('20181203021853'),
('20181204193439'),
('20181204215309'),
('20181207011115'),
('20181213184704'),
('20181213185533'),
('20181219235220'),
('20181226021420'),
('20190103124649'),
('20190103124754'),
('20190117114553'),
('20190201012802'),
('20190203180359'),
('20190225031541'),
('20190225031625'),
('20190226003449'),
('20190304152020'),
('20190306145741'),
('20190307234537'),
('20190314181829'),
('20190316190352'),
('20190317135723'),
('20190403141604'),
('20190409054914'),
('20190420025523'),
('20190509164208'),
('20190511134027'),
('20190511152737'),
('20190519130537'),
('20190529143559'),
('20190627222225'),
('20190627222826'),
('20190701022101'),
('20190705002136'),
('20190706233204'),
('20190715031050'),
('20190715164535'),
('20190726175042'),
('20190729185330'),
('20190805123746'),
('20190807135426'),
('20190815225426'),
('20190819134503'),
('20190820003045'),
('20190823221802'),
('20190901035623'),
('20190901040524'),
('20190904222339'),
('20190914202517'),
('20190915194355'),
('20190917213523'),
('20190927124642'),
('20190927232842'),
('20191001213028'),
('20191007013357'),
('20191031163205'),
('20191212003415'),
('20191212163405'),
('20191218153258'),
('20200113125135'),
('20200114113335'),
('20200119112504'),
('20200126203551'),
('20200301102028'),
('20200306035625'),
('20200309150742'),
('20200312144258'),
('20200312162302'),
('20200312185443'),
('20200317021758'),
('20200407201300'),
('20200407202420'),
('20200417125749'),
('20200508212852'),
('20200510110808'),
('20200510181721'),
('20200516180352'),
('20200516183822'),
('20200518083523'),
('20200521180606'),
('20200529214050'),
('20200601222558'),
('20200605155027'),
('20200608113046'),
('20200614002136'),
('20200620164023'),
('20200622213645'),
('20200627125810'),
('20200628133322'),
('20200630190240'),
('20200630190544'),
('20200908193330'),
('20200917192924'),
('20200917193034'),
('20200917193528'),
('20200917222316'),
('20200917222734'),
('20201008202037'),
('20201008220312'),
('20201017233919'),
('20201017234926'),
('20201206004238'),
('20201218054746'),
('20210221045109'),
('20210306164523'),
('20210308133107'),
('20210322164601'),
('20210323114347'),
('20210324171613'),
('20210416200740'),
('20210421121431'),
('20210425135952'),
('20210502233513'),
('20210505174616'),
('20210507001928'),
('20210526193025'),
('20210820214848'),
('20210901122351'),
('20210910070426'),
('20210910182158'),
('20210928180813'),
('20211005170237'),
('20211022212136'),
('20211104152901'),
('20211129180721'),
('20211202184856'),
('20211217192708'),
('20220111182328'),
('20220203145422'),
('20220203182927'),
('20220205141909'),
('20220211140727'),
('20220219181316'),
('20220224032042'),
('20220227193955'),
('20220307161659'),
('20220307182724'),
('20220322201102'),
('20220402235810'),
('20220418211320'),
('20220525140644'),
('20220601164238'),
('20220608181416'),
('20220610102254'),
('20220625183513'),
('20220629052930'),
('20220708001921'),
('20220711175354'),
('20220712093107'),
('20220712143207'),
('20220712143219'),
('20220712143235'),
('20220718130723'),
('20220718180414'),
('20220721170046'),
('20220805193734'),
('20220808181920'),
('20220808204345'),
('20220808204349'),
('20220808204750'),
('20220808210605'),
('20220817205647'),
('20220902190624'),
('20220919200627'),
('20220920162400'),
('20220928200505'),
('20220930000848'),
('20221011162335'),
('20221012194024'),
('20221018174555'),
('20221019162359'),
('20221020150334'),
('20221021172353'),
('20221021172611'),
('20221022143208'),
('20221022152927'),
('20221022153455'),
('20221022153555'),
('20221022161420'),
('20221022172530'),
('20221022182735'),
('20221022192931'),
('20221025144642'),
('20221104181314'),
('20221118165324'),
('20221128192530'),
('20221129204959'),
('20221201173549'),
('20221208225026'),
('20221212195110'),
('20221213021412'),
('20221220135332'),
('20221221011644'),
('20221221150418'),
('20221227220932'),
('20221229101327'),
('20221229120000'),
('20221229122549'),
('20230101055106'),
('20230101055823'),
('20230101081325'),
('20230109194712'),
('20230110164246'),
('20230111230654'),
('20230123153647'),
('20230125203203'),
('20230126002921'),
('20230130215152'),
('20230131154233'),
('20230131154840'),
('20230201214716'),
('20230202000001'),
('20230206182026'),
('20230206191959'),
('20230216153516'),
('20230217191343'),
('20230221000001'),
('20230224022915'),
('20230301162807'),
('20230302165241'),
('20230306192629'),
('20230310152402'),
('20230310180826'),
('20230311190110'),
('20230311190111'),
('20230312201314'),
('20230313151010'),
('20230314183452'),
('20230316200935'),
('20230316200936'),
('20230321132705'),
('20230321202450'),
('20230322100332'),
('20230327200424'),
('20230404125452'),
('20230406202132'),
('20230410164500'),
('20230418200029'),
('20230418234134'),
('20230419205747'),
('20230420155450'),
('20230421152216'),
('20230424000001'),
('20230424210318'),
('20230425015128'),
('20230425225533'),
('20230425235136'),
('20230426201619'),
('20230427220936'),
('20230428204334'),
('20230428300000'),
('20230504000001'),
('20230508165559'),
('20230512161704'),
('20230515161419'),
('20230519145750'),
('20230521003044'),
('20230523161930'),
('20230525151610'),
('20230530194553'),
('20230601161400'),
('20230601164632'),
('20230602134201'),
('20230605125803'),
('20230609134211'),
('20230609154822'),
('20230612183601'),
('20230613191848'),
('20230616175922'),
('20230622200847'),
('20230623145159'),
('20230626143215'),
('20230626150347'),
('20230710144348'),
('20230711165306'),
('20230713204335'),
('20230721145338'),
('20230725235434'),
('20230727130317'),
('20230728160002'),
('20230729011055'),
('20230802161850'),
('20230831133211'),
('20230913000000'),
('20230920171818'),
('20230921174531'),
('20230921184328'),
('20230925194016'),
('20230926132013'),
('20230926174655'),
('20231004155208'),
('20231005181026'),
('20231010183722'),
('20231013184518'),
('20231017160656'),
('20231018124227'),
('20231106203212'),
('20231110082348'),
('20231113000000'),
('20231113190644'),
('20231114211840'),
('20231116141044'),
('20231120165224'),
('20231204211145'),
('20231206143446'),
('20231215054115'),
('20231220063852'),
('20240105165609'),
('20240109144646'),
('20240119150135'),
('20240125191237'),
('20240126192156'),
('20240130000000'),
('20240130000001'),
('20240201174520'),
('20240201192221'),
('20240213000000'),
('20240214153337'),
('20240223163947'),
('20240226000000'),
('20240227000000'),
('20240228180002'),
('20240229144316'),
('20240305132742'),
('20240313002703'),
('20240313172509'),
('20240313173854'),
('20240318135717'),
('20240409192742');


