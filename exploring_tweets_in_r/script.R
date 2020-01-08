# Exploring tweets in R #

library(rtweet) ; library(tidyverse) ; library(tidytext)

# search for tweets
tweets <- search_tweets(q = "#ClimateEmergency", 
                        n = 18000,
                        include_rts = FALSE,
                        `-filter` = "replies",
                        lang = "en") 

# inspect sample
tweets %>% 
  sample_n(5) %>%
  select(created_at, screen_name, text, favorite_count, retweet_count)

# export results
write_as_csv(tweets, "tweets.csv")

# timeline of tweets
ts_plot(tweets, "hours") +
  geom_line(colour = "#F29545", size = 1) +
  geom_hline(yintercept = 0, size = 1, colour = "#333333") +
  scale_y_continuous(expand = c(0.005, 0.005)) +
  labs(x = NULL, y = NULL,
       title = "Frequency of tweets with a #ClimateEmergency hashtag",
       subtitle = paste0(format(min(tweets$created_at), "%d %B %Y"), " to ", format(max(tweets$created_at),"%d %B %Y")),
       caption = "Data collected from Twitter's REST API via rtweet") +
  theme_minimal() +
  theme(panel.grid.major.x = element_blank(),
        panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"),
        plot.caption = element_text(margin = margin(t = 15)))

# top tweeting location
tweets %>% 
  filter(!is.na(place_full_name)) %>% 
  count(place_full_name, sort = TRUE) %>% 
  top_n(5)  

# most frequently shared link
tweets %>% 
  filter(!is.na(urls_expanded_url)) %>% 
  count(urls_expanded_url, sort = TRUE) %>% 
  top_n(5)

# most retweeted tweet
tweets %>% 
  arrange(-retweet_count) %>%
  slice(1) %>% 
  select(created_at, screen_name, text, retweet_count)

library(tweetrmd)
tweet_screenshot(tweet_url("MikeHudema", "1212806892390666241"))

# most liked tweet
tweets %>% 
  arrange(-favorite_count) %>%
  top_n(5, favorite_count) %>% 
  select(created_at, screen_name, text, favorite_count)

# top tweeters
tweets %>% 
  count(screen_name, sort = TRUE) %>%
  top_n(10) %>%
  mutate(screen_name = paste0("@", screen_name))

# top emoji
library(emo)
tweets %>%
  mutate(emoji = ji_extract_all(text)) %>%
  unnest(cols = c(emoji)) %>%
  count(emoji, sort = TRUE) %>%
  top_n(10)

# top hashtags
tweets %>% 
  unnest_tokens(hashtag, text, "tweets", to_lower = FALSE) %>%
  filter(str_detect(hashtag, "^#"),
         hashtag != "#ClimateEmergency") %>%
  count(hashtag, sort = TRUE) %>%
  top_n(10)

# top username mentions
tweets %>% 
  unnest_tokens(mentions, text, "tweets", to_lower = FALSE) %>%
  filter(str_detect(mentions, "^@")) %>%  
  count(mentions, sort = TRUE) %>%
  top_n(10)

# top words
words <- tweets %>%
  mutate(text = str_remove_all(text, "&amp;|&lt;|&gt;")) %>% 
  unnest_tokens(word, text, token = "tweets") %>%
  filter(!word %in% stop_words$word,
         !word %in% str_remove_all(stop_words$word, "'"),
         str_detect(word, "[a-z]"),
         !str_detect(word, "^#"),         
         !str_detect(word, "@\\S+")) %>%
  select(screen_name, word, created_at, is_retweet, hashtags) %>% 
  count(word, sort = TRUE)

library(wordcloud) 
words %>% 
  with(wordcloud(word, n, random.order = FALSE, max.words = 100, colors = "#F29545"))
