#Created by Tony Suriyathep on 2013.12.30



#==================================================================================================#

#Shuffle array



@shuffle = (a) ->

  i = a.length

  while --i > 0

    j = ~~(Math.random() * (i + 1)) # ~~ is a common optimization for Math.floor

    t = a[j]

    a[j] = a[i]

    a[i] = t

  return a





#==================================================================================================#

#String stuff



@matchAt = (s, frag, i) -> s[i...i+frag.length] == frag

@startsWith = (s, frag) -> @matchAt s, frag, 0

@endsWith = (s, frag) -> @matchAt s, frag, s.length - frag.length





#==================================================================================================#

#Number stuff



#Returns an integer

@randomInteger = (min,max)->

	if min==max then return min

	return min+Math.floor(Math.random()*(1+max-min))



#Returns a decimal

@randomDecimal = (min,max)->

	if min==max then return min

	return min+(Math.random()*(1+max-min))



#Returns 0 or 1

@randomBoolean = ()->

	return Math.floor(Math.random()*2)==1



@rotateNumber = (index,maxNum)->

	maxNum++;

	if index>=maxNum then index=index%maxNum #Handle positive

	else if index<0 then index=(index%maxNum)+maxNum #Handle negative

	return if index==maxNum then 0 else index





#==================================================================================================#

#General



#http://coffeescriptcookbook.com/chapters/classes_and_objects/cloning

@clone = (obj) ->

  if not obj? or typeof obj isnt 'object' then return obj



  if obj instanceof Date then return new Date(obj.getTime())



  if obj instanceof RegExp

    flags = ''

    flags += 'g' if obj.global?

    flags += 'i' if obj.ignoreCase?

    flags += 'm' if obj.multiline?

    flags += 'y' if obj.sticky?

    return new RegExp(obj.source, flags)



  newInstance = new obj.constructor()



  for key of obj

    newInstance[key] = clone obj[key]



  return newInstance





#==================================================================================================#







