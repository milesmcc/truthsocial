# frozen_string_literal: true

require 'rails_helper'

describe StatusLengthValidator do
  describe '#validate' do
    let(:errors) { instance_double(ActiveModel::Errors, add: nil) }

    shared_examples 'a valid status' do
      it 'will NOT add errors' do
        subject.validate(status)
        expect(errors).not_to have_received(:add)
      end
    end
    shared_examples 'an invalid status' do
      it 'will add errors' do
        subject.validate(status)
        expect(errors).to have_received(:add)
      end
    end

    context 'with a status with nil text' do
      let(:status) do
        instance_double(
          Status,
          errors: errors,
          local?: true,
          reblog?: false,
          spoiler_text: nil,
          text: nil,
        )
      end

      it_behaves_like 'a valid status'
    end


    context 'with a status with invalid text length' do
      let(:status) do
        instance_double(
          Status,
          errors: errors,
          local?: local,
          reblog?: reblog,
          spoiler_text: 'x' * (StatusLengthValidator::MAX_CHARS + 1),
          text: 'x' * (StatusLengthValidator::MAX_CHARS + 1),
        )
      end

      context "when the status is remote" do
        let(:local) { false } # only this matters
        let(:reblog) { false }

        it_behaves_like 'a valid status'
      end

      context 'with local reblogs' do
        let(:local) { true }
        let(:reblog) { true }

        it_behaves_like 'a valid status'
      end
    end
    
    context "with spoiler_text.length == MAX_CHARS" do
      let(:status) do
        instance_double(
          Status,
          errors: errors,
          local?: true,
          reblog?: false,
          spoiler_text: 'x' * StatusLengthValidator::MAX_CHARS,
          text: '',
        )
      end
      it_behaves_like 'a valid status'
    end

    context "with text.length == MAX_CHARS" do
      let(:status) do
        instance_double(
          Status,
          errors: errors,
          local?: true,
          reblog?: false,
          spoiler_text: '',
          text: 'x' * StatusLengthValidator::MAX_CHARS,
        )
      end
      it_behaves_like 'a valid status'
    end
    
    context "with spoiler_text > MAX_CHARS" do
      let(:status) do
        instance_double(
          Status,
          errors: errors,
          local?: true,
          reblog?: false,
          spoiler_text: 'x' * (StatusLengthValidator::MAX_CHARS + 1),
          text: '',
        )
      end
      it_behaves_like 'an invalid status'
    end

    context "with spoiler_text > MAX_CHARS" do
      let(:status) do
        instance_double(
          Status,
          errors: errors,
          local?: true,
          reblog?: false,
          spoiler_text: '',
          text: 'x' * (StatusLengthValidator::MAX_CHARS + 1),
        )
      end
      it_behaves_like 'an invalid status'
    end

    context 'text.length + spoiler_text.length == MAX_CHARS' do
      let(:status) do
        instance_double(
          Status,
          errors: errors,
          local?: true,
          reblog?: false,
          spoiler_text: 'a' * (StatusLengthValidator::MAX_CHARS / 2),
          text: 'b' * (StatusLengthValidator::MAX_CHARS / 2),
        )
      end
      it_behaves_like 'a valid status' 
    end
    
    context 'text.length + spoiler_text.length > MAX_CHARS' do
      let(:status) do
        instance_double(
          Status,
          errors: errors,
          local?: true,
          reblog?: false,
          spoiler_text: 'a' * (StatusLengthValidator::MAX_CHARS / 2),
          text: 'b' * (StatusLengthValidator::MAX_CHARS / 2 + 1),
        )
      end
      it_behaves_like 'an invalid status'
    end

    context "with a url > URLPlaceholder::LENGTH" do
      let(:url) { "http://#{'b' * URLPlaceholder::LENGTH}.com/" }

      # create a balance that will push the overall length to the limit
      # the extra space is substracted to account for the space between the text and the url
      let(:balance) do
        StatusLengthValidator::MAX_CHARS - 
        URLPlaceholder::LENGTH - 1
      end

      let(:status) do
        instance_double(
          Status,
          errors: errors,
          local?: true,
          reblog?: false,
          spoiler_text: '',
          # an extra space is added to parse the url
          text: text,
        )
      end

      context "with text == MAX_CHARS" do
        let(:text) { ('a' * balance) + " " + url }
        it_behaves_like 'a valid status'
      end
      context "with one too many characters" do
        let(:text) { "!" + ('a' * balance) + " " + url }
        it_behaves_like 'an invalid status'
      end
    end

    context "with a url < URLPlaceholder::LENGTH" do
      let(:url) { "http://b.com/" }

      let(:balance) do
        StatusLengthValidator::MAX_CHARS - 
        url.length - 1
      end

      let(:status) do
        instance_double(
          Status,
          errors: errors,
          local?: true,
          reblog?: false,
          spoiler_text: '',
          text: text
        )
      end

      context "with text == MAX_CHARS" do
        let(:text) { ('a' * balance) + " " + url }
        it_behaves_like 'a valid status'
      end
      context "with one too many characters" do
        let(:text) { "!" + ('a' * balance) + " " + url }
        it_behaves_like 'an invalid status'
      end
    end

    it 'counts only the front part of remote usernames' do
      text   = ('a' * 975) + " @alice@#{'b' * 30}.com"
      status = double(spoiler_text: '', text: text, errors: double(add: nil), local?: true, reblog?: false)

      subject.validate(status)
      expect(status.errors).to_not have_received(:add)
    end
  end
end
