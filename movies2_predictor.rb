#This class is used to create a prediction based off the data that is processed by the main MovieData class.  It uses a user-user collaborative-filtering algorithm with a user-modification and item-modification predictive modifiers.  

#Author:  Bryan Turcotte

class MoviePredictor

  def initialize(user_hash, movie_hash)
    @user_hash = user_hash
    @movie_hash = movie_hash
  end
    
#Uses a collaborative filtering algorithm to create base prediction.  It takes the average of the ratings of each of the users in the predictive data group, and then uses it as the initial prediction.
  def predict(predictive_users, movie_id, user_id)
    score = 0.0
    total = 0.0
    tally = 0.0
    predictive_users.each do |user|
      score = rating(user, movie_id).to_i #Takes the average score of users in the predictive 
      #array and sets that to the prediction.  
      if score != 0
        total += score
        tally += 1
      end
    end
    
    base_prediction = (total / tally).to_f
    prediction = prediction_modifiers(base_prediction, movie_id, user_id)
    return prediction
  end
  
  #Modifies the prediction based off of difference of our collaborative filtering algorithm's guess and the movie's average rating, as well as the user's average rating for any given movie. The actual modifying  values (.2, .5) come from testing accuracy on the training set data
  def prediction_modifiers(base_prediction, movie_id, user_id) 
    modified_prediction = movies_average_modification(base_prediction, movie_id, user_id)
    modified_prediction = users_pattern_rating(base_prediction, modified_prediction, movie_id, user_id)
    if modified_prediction > 5 #checks if our modified result ended out of bounds (0 is min, 5 max)
      return 5
    elsif modified_prediction < 0
      return 1
    end
    return modified_prediction

  end

#modifying based off of user's own rating average.   
  def users_pattern_rating(base_prediction, modified_prediction, movie_id, user_id)
    user_rating_avg = 0.0  
    movies = @user_hash[user_id]
    movies.each do |hash|
      user_rating_avg += hash[hash.keys[0]].to_i
    end
    user_rating_avg = user_rating_avg / @user_hash[user_id].length
    if base_prediction > user_rating_avg
      modified_prediction -= 0.5 *(base_prediction - user_rating_avg).abs 
    elsif base_prediction < user_rating_avg
      modified_prediction += 0.5 * (base_prediction - user_rating_avg).abs
    end
    return modified_prediction
  end
  
  #Modifies the prediction based off of movie's average ratings
  def movies_average_modification(base_prediction, movie_id, user_id)
    
    modified_prediction = base_prediction 
    popular_opinion = rating_average(movie_id)
    if popular_opinion > 3 && base_prediction < 3
      modified_prediction += 0.2
    elsif popular_opinion < 3 && base_prediction > 3
      modified_prediction -= 0.2
    end
    return modified_prediction
  end
  
  #Takes the array of user-rating pairings, converts the rating to an int, and uses the sum of ratings / count of ratings to calculate its average rating.
  def rating_average(movie_id)  
    accumulator = 0.0
    user_list = @movie_hash[movie_id]
    if user_list == nil #If nobody saw the movie, return 0.
      return 0
    end
    user_list.each do |hash|
      accumulator +=  hash[hash.keys[0]].to_i
    end
    return  average = (accumulator / @movie_hash[movie_id].length)
  end

  #Calculates the rating of a movie, to be used as a prediction metric.  
  def rating(user_id, movie_id) 
    movies = @user_hash[user_id]
    movies.each do |movie|
      if movie[movie_id]
        return movie[movie_id]
      end
    end
    return 0
  end
end
