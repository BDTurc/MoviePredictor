#This class works by reading in data from a file containing movie rating information in the form of user_id, movie_id, rating_val, timestamp_val. It can perform several functions on these values, but its main job is to predict movie ratings. It does this by utilizing a user-based collaborative-filtering algorithm, which meansthat it predicts a user's rating by first finding other people it can use as a model.It finds that group by checking who has seen the same movies as the user in question, and whether or not they rated it the same way.  The top 20 most similar users (those who often saw the same movies and gave the same rating as the user in question) become our user-model.It takes the subset of those users who also saw the movie we are predicting for, and byfinding their average, it gives us a base prediction model.  We then modify this by both an item-value (a modifier based off of the average rating that the movie received)and a user-value (a modifier based only off the user's rating trends).  I originally employed 8 different modifiers, and each had several different valuesbut the cost of calculation almost doubled, and the error-mean only ever dropped to a low of .78The predictions that remain are the most cost-effective, keeping us around .8 for our error-meanwhile only increasing the running time by about 20%.

#Author:  Bryan Turcotte 

require_relative 'movies2_test.rb' #Our MovieTest class file
require_relative 'movies2_predictor.rb' #Our MoviePredictor class file

class MovieData
  def initialize(folder, string = 'u.data') 
    @user_hash = Hash.new #Hash with all users as keys to an array containing
                          #the movies they've seen and the ratings they gave.
    @movie_hash = Hash.new #Hash with all movies as keys to an array containing
                           # all users who viewed it and their ratings.
    @best_match = Array.new #Generated by most_similar
    @user_marker = '0' #Used by predict to determine if our current "best match"
                       #array can be used for this user as well"
    if string == 'u.data'
      @trainingfile = 'u.data'
    else
    @trainingfile = "#{folder}/#{string}.base"
    @testfile = "#{folder}/#{string}.test"
    end
  end
  
#Loads data into two groups:  A hash of arrays containing movie-rating pairs and a hash of arrays containing user-rating pairs
  def load_data() 
    target_data = open(@trainingfile, "r")
    target_data.each_line do  |line|
      reviewer_val, movie_val, rating_val, timestamp_val = line.split
      userarray = [{reviewer_val => rating_val}]
      moviearray = [{movie_val => rating_val}]
      if @movie_hash.has_key?(movie_val) #adding arrays to the hashes...
        @movie_hash[movie_val].push({reviewer_val => rating_val})
      else 
        @movie_hash[movie_val] = userarray
      end
      
      if @user_hash.has_key?(reviewer_val)
        @user_hash[reviewer_val].push({movie_val => rating_val})
      else
        @user_hash[reviewer_val] = moviearray
      end
      
    end   
    target_data.close   
  end

#Returns an array of all the movies a user has seen by accessing the hash of movie-rating pairs using the user as the key. 
  def movielist(user_id)  
    moviearray = Array.new
    movie_list = @user_hash[user_id]
    movie_list.each do |hash| #pushes each movie (key[0]) into the array
      moviearray.push(hash.keys[0])
    end
    return moviearray
  end

  #Returns an array of all the users who viewed a movie by accessing the hash of user-rating pairs using the movie as the key
  def viewers(movie_id) 
    userarray = Array.new
    userlist = @movie_hash[movie_id]
    if userlist == nil
      return 0
    end
    userlist.each do |hash|#pushes each viewer (key[0]) into the array
      userarray.push(hash.keys[0])
    end
    return userarray
  end

#Calculates rating by pulling up the rating of all the movies that a user has seen, and if the user has seen the movie, returns the rating value. 
  def rating(user_id, movie_id) 
    movielist = @user_hash[user_id]
    movielist.each do |hash|
      if hash[movie_id]
        return hash[movie_id]
      end
    end
    return 0
  end
  
# Prediction_data  first checks if the user we are predicting is the same as the previous, if it is, then the method uses the previously stored predictive data. If it is not, the method gathers the list of best_matches from "most_similar," as well as the list of all viewers of the movie in question. If no one else saw the movie, it will predict 1, and if no one is a good match to predict off of, it predicts the movie average rating. Otherwise it calls the predict method to use a basic collaborative filtering algorithm as our initial prediction value.
  def prediction_data(user_id, movie_id)
    if user_id != @user_marker
      @best_match.clear
      most_similar(user_id) #will return the top 20 best matched viewers.
      @user_marker = user_id
    end

    matched_movies = viewers(movie_id) #list of all users who saw the movie
    if matched_movies == 0
      prediction = 1
      return prediction
    end
    predictive_users = (@best_match & matched_movies) #sets our predictive data to be the subset 
                                                      # of best_match that has also seen this movie
   
    my_prediction = MoviePredictor.new(@user_hash, @movie_hash)
    
    if predictive_users.empty? 
      return my_prediction.rating_average(movie_id)
    end
    
    return my_prediction.predict(predictive_users, movie_id, user_id)
  end
  
  #Takes all the movies a user has seen and for each movie, finds all other users who viewed it and rated it the SAME.  NOTE: because of the structure of @user_hash and @movie_hash, the nested while loop causes this function to operate on O(n) time, not n^2 time. This is bound by the data set, as the method's number of checks cannot surpass the number of ratings given in the movie data set. 
  def most_similar(user_id)   
    reviewer_similarity = Hash.new
    user_movies_list = @user_hash[user_id]
    user_movies_list.each do |hash| #nested while loop, operated in O(n) time.  
      userlist = @movie_hash[hash.keys[0]]
      userlist.each do |moviehash|
        #If a user has seen this movie as well and rated it the same, he/she is added
        # to a hash which indicates how many times they have been added.
        if (moviehash[moviehash.keys[0]] == hash[hash.keys[0]] && user_id != moviehash.keys[0])
          user =  moviehash.keys[0]
          #hash uses user_id as key and maps them to a value corresponding to how many 
          #times they have been found to be a "good match" for the user.
          if reviewer_similarity.has_key?(user) 
            reviewer_similarity[user] += 1
          else
            reviewer_similarity[user] = 1
          end
        end
      end
    end
    best_match(reviewer_similarity)
  end

    #sets best_match to be only the top 20 users.
    #Interestingly, changing this to be even the top 100, and changing the best match to take
    #anyone with just similar ratings (not exact matches) does not greatly change our results.
    def best_match(reviewer_similarity)
      sorted_list = reviewer_similarity.sort_by {|k,v| -v}
      sorted_list[0..20].each do |val|
        @best_match.push(val[0])
      end
    end
  
#Runs tests using data from the training file (to create our predictive_user array) and applies it to the data in the testing file.  Creates Class MovieTest which handles all of the error data for our predictions. NOTE:  The test file is sorted by user, which is optimal for this program. 
  def run_test(amount = 20000) #if no amount specified, run all 20000 tests.  
    if @testfile == nil #if originally no test file was specified, indicate and exit.
      puts "No data to test!"
      exit(0)
    end
    results_array = Array.new
    target_data = open(@testfile, "r")
    target_data.take(amount).each do |line| #reading in specified amount of data to test.
      reviewer_val, movie_val, rating_val, timestamp_val = line.split
      prediction = prediction_data(reviewer_val, movie_val).round(2) #calls prediction on user from the test_set.
      results = [reviewer_val, movie_val, rating_val, prediction]
      results_array.push(results)
    end  
    analyze_data(results_array)
  end

#Generates an object of MovieTest class and runs its methods to analyze our data.
  def analyze_data(results_array)
    my_results = MovieTest.new(results_array) #create object of the MovieTest class to analyze data.
    puts "Mean error = #{my_results.mean_error}"
    puts "Stddev = #{my_results.stddev}"
    puts "rms error = #{my_results.rms_error}"
    my_results.to_array
  end
end

my_movie = MovieData.new('ml-100k', :u1)
btime = Time.now
my_movie.load_data()

my_movie.run_test()

etime = Time.now
puts "Total Time = #{(etime - btime) * 1000} "


