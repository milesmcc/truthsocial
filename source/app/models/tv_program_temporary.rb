# frozen_string_literal: true
# == Schema Information
#
# Table name: tv.programs_temporary
#
#  channel_id  :integer          not null, primary key
#  name        :text             not null
#  image_url   :text             not null
#  start_time  :datetime         not null, primary key
#  end_time    :datetime         not null
#  description :text             not null
#
class TvProgramTemporary < TvProgram
  self.table_name = 'tv.programs_temporary'
end
