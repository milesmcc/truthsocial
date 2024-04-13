# frozen_string_literal: true

module Mastodon::MaterializedViews
  class << self
    def initialize
      connection.execute(<<~SQL)
        do $$
        declare
                "var_view"      text;
        begin
                for "var_view" in
                        select                  "pg_catalog"."quote_ident" ("n"."nspname")||'.'||"pg_catalog"."quote_ident" ("c"."relname")
                                from            "pg_catalog"."pg_class" "c"
                                join            "pg_catalog"."pg_namespace" "n"
                                        on      "n"."oid" = "c"."relnamespace"
                                where           "c"."relkind" = 'm'
                loop
                        execute ('refresh materialized view '||"var_view");
                end loop;
        end
        $$;
      SQL
    end

    private

    def connection
      ActiveRecord::Base.connection
    end
  end
end
