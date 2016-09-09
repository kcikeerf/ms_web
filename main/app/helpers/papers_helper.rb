module PapersHelper

	def download_list(type)		
		case type
		when 'original_paper_answer'
			%w{paper answer}
		when 'modified_paper_answer_emptyscore'
			%w{revise_paper revise_answer empty_file}
		when 'imported_score'
			%w{filled_file}
		when 'user_password_reporturl'
			%w{usr_pwd_file}
		else
			[]
		end
	end


    def subject_list
    	Common::Subject::List
    end

    def grade_list
        Common::Grade::List 
    end

    def node_version_list
        Common::NodeVersion::List
    end

    def term_list
        Common::Term::List
    end

    def quiz_type_list
        Common::Paper::QuizType
    end

    def difficulty_list
    	Common::Paper::Difficulty
    end
end
