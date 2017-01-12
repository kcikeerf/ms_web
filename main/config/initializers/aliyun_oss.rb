require 'aliyun/oss'
module SwtkAliOss
	module_function

	Const = {
    :endpoint => 'oss-cn-qingdao.aliyuncs.com',
    :access_key_id => 'LTAIGJpnWaBVjopT',
    :access_key_secret => '5AxztdmysMSuQXRDVemvL2Psa4bfCB',
    :default_bucket => 'k12ke-report',
    :grade_report_bucket => 'grade-report',
    :class_report_bucket => 'class-report',
    :pupil_report_bucket => 'pupil-report'
  }

  def bkt_clt
    Aliyun::OSS::Client.new(
    endpoint: Const[:endpoint],
    access_key_id: Const[:access_key_id],
    access_key_secret: Const[:access_key_secret])
  end

  def get_bucket name
    bkt_name = name.blank?? Const[:default_bucket]:name
    bkt_clt.get_bucket(name)
  end

  def put_report_json bucket, key, value
    bkt = get_bucket bucket
    bkt.put_object(key){|s| s << value}
  end

  def get_report_json bucket, key
    result = ""
    bkt = get_bucket bucket
    bkt.get_object(key){|c| result << c}
    result.force_encoding('utf-8')
  end

  def get_report_json_url bucket, key
    result = ""
    bkt = get_bucket bucket
    bkt.object_url(key)
  end

  def list_report_objs bucket, key
    bkt = get_bucket bucket
    rpt_keys = bkt.list_objects(:prefix => key).map{|o| o.key}
  end

  def del_report_obj bucket, key
    bkt = get_bucket bucket
    bkt.delete_object(key)
  end

  def response_report_url bucket, key
    result = nil
    bkt = get_bucket bucket

    if bkt.object_exists?(key)
      #result = get_report_json_url(bucket,key)
      result = get_report_json(bucket,key)
    else
      target_model = nil
      case bucket
      when "grade-report"
        target_model = Mongodb::GradeReport
      when "class-report"
        target_model = Mongodb::ClassReport
      when "pupil-report"
        target_model = Mongodb::PupilReport
      end
      return result unless target_model
      
      rpt = target_model.find(key)
      return result unless rpt
      
      put_report_json(bucket, key, rpt.report_json)
      #result = get_report_json_url(bucket,key) if bkt.object_exists?(key)
      result = get_report_json(bucket,key) if bkt.object_exists?(key)
    end
    return result
  end

end
