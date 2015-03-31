#This class takes in the results from an object of class MovieData. It runs several calculations on the results of the predictive functions of MovieDataIt will generate the mean error, root-mean-square error, and standard deviation of error.How these calculations are achieved is explained in each method. In terms of calculations for std_dev and rms, the method uses (n), opposed to (n-1).  

#Author:  Bryan Turcotte 


class MovieTest
  def initialize(results)
    @results = results
    @differences_array = get_differences #Used in all error calculations
  end

  #Takes all prediction values from MovieData.run_test, as well as all the rating values for each of those movies.  Determines the mean of the difference.
  def mean_error() 
      
    difference = 0.0
    @differences_array.each do |difference_value|
      difference += difference_value.abs
    end
    error_val = difference / @differences_array.length #@differences_array.length is a substitute for our n-value
    return error_val.round(2)
  end

  #Calculates Root Mean Square error by taking the sum of the squared differene between each prediction and the actual rating, and dividing by the number of tests
  def rms_error() 
    difference_squared = 0.0
    @differences_array.each do |difference_value|
      difference_squared +=  difference_value ** 2
    end
    value = difference_squared / @differences_array.length
    error_val = Math.sqrt(value)
    return error_val.round(2)
  end

 #Calculates the standard deviation of the error value (the square-root of the sum of values that are given when predicted value is subtracted from actual value, then the mean error is subtracted from that value and  this result is squared. 
  def stddev() 
    mean_val = mean_error
    difference_mean = 0.0
    std_dev = 0.0
    @differences_array.each do |difference_value|
      difference_mean += (difference_value - mean_val) ** 2
    end
    difference_mean = difference_mean / @differences_array.length
    std_dev = Math.sqrt(difference_mean) 
      
    return std_dev.round(2)
  end
  
#All the error calculations rely on the difference between predicted and true values, so this calculates that once and stores the differences in an array.
  def get_differences()
    differences_array = Array.new
    @results.each do |tuple|
      actual_rating = tuple[2].to_f
      predicted_rating = tuple[3].to_f
      differences_array.push(actual_rating - predicted_rating)
    end
    return differences_array
  end

#Turns the results table (an array of arrays) into a 1-D array, where each line is in the format [user_id, movie_id, true rating, prediction]
  def to_array() 
    viewable_array = Array.new
    @results.each do |tuple|
      results = tuple.join(", ")
      viewable_array.push(results)
    end
    return viewable_array
  end
end
