#swtk user patch

class Hash
  def insert_before(key, arr)
    arr = to_a
    pos = arr.index(arr.assoc(key))
    if pos
      arr.insert(pos, arr)
    else
      arr << arr
    end
    replace Hash[arr]
  end
end

class Array
  def insert_before(key, kvpair)
    pos = index(assoc(key))
    if pos
      insert(pos, kvpair)
    else
      self << kvpair
    end
  end
end