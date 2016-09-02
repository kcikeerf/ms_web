class TeachersController < ApplicationController
  layout 'user'

  def my_home
    @current_user = current_user
  end

  def my_pupil
    pupils = current_user.teacher.pupils
    grade_arr = pupils.all.map(&:grade).uniq.sort{|a,b| 
      Common::Locale.mysort(Common::Grade::Order[a.nil?? "":a.to_sym],Common::Grade::Order[b.nil?? "":b.to_sym]) 
    }
    @grades = deal_label('dict', grade_arr)

    klass_arr = pupils.all.map(&:classroom).uniq.sort{|a,b|
      Common::Locale.mysort(Common::Klass::Order[a.nil?? "":a.to_sym],Common::Klass::Order[b.nil?? "":b.to_sym])
    }
    klass_arr.compact!
    @classrooms = klass_arr.map{|k| [Common::Klass::klass_label(k), k]}

    @pupils = pupils.by_grade(params[:grade])
      .by_classroom(params[:classroom])
      .by_keyword(params[:keyword])
      .page(params[:page])
      .per(Common::Page::PerPage)
  end

  def test_report
    @papers = current_user.teacher.papers.page(params[:page]).per(Common::Page::PerPage)

  end

  private

  def teacher_params
  	params.require(:teacher).permit()
  end

end
