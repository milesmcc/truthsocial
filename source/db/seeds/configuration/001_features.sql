insert into		"configuration"."features" ("name")
	values		('trending_statuses'),
			('trending_tags'),
			('status_tag_cache'),
			('statistics'),
			('ancestor_statuses'),
			('trending_groups')
	on		conflict
		do	nothing;
