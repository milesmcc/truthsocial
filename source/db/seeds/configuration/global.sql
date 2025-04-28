insert into		"configuration"."global" (
				"name",
				"value"
			)
	values		(
				'RAILS_ENV',
				'development'
			),
			(
				'WEB_DOMAIN',
				'localhost:3000'
			),
			(
				'S3_ENABLED',
				'false'
			)
	on		conflict
		do	nothing;
