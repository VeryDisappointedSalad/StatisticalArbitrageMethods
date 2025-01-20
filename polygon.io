import requests
import pandas as pd
from datetime import datetime, timedelta
import time
from google.colab import files

API_KEY = ""  # Your Polygon.io key
TICKER  = "SPY"                             # We'll combine ticker=SPY + search=keyword
SLEEP_SECONDS = 12
LIMIT = 50  # Polygon's single-call max items

##########################
# The large keyword list
##########################
keywords = [
    # 1) Economics / US Economy
    "United States economy",
    "economic growth",
    "economic slowdown",
    "recession",
    "recovery",
    "GDP",
    "U.S. GDP",
    "Gross Domestic Product",
    "unemployment",
    "unemployment rate",
    "jobless claims",
    "initial claims",
    "continuing claims",
    "inflation",
    "CPI",
    "Consumer Price Index",
    "PCE",
    "Personal Consumption Expenditures",
    "core inflation",
    "consumer spending",
    "housing market",
    "bond yields",
    "Treasury yields",
    "Treasury yield",
    "10-year Treasury yield",
    "2-year Treasury yield",
    "yield curve",
    "yield curve inversion",
    "interest rates",
    "rate hike",
    "rate cut",
    "rate hold",
    "tightening",
    "easing",
    "stock market",
    "S&P 500",
    "Nasdaq",
    "Dow Jones",
    "equities",
    "monetary policy",
    "soft landing",
    "hard landing",
    "credit tightening",
    "liquidity tightening",
    "ISM",
    "PMI",
    "Federal Reserve",
    "Fed",
    "FOMC",
    "Fed meeting",
    "FOMC meeting",
    "FOMC minutes",
    "Fed minutes",
    "Jerome Powell",
    "hawkish",
    "dovish",
    "interest rate decision",
    "terminal rate",
    "Fed statement",
    "Fed press conference",
    "inflation target",
    "quantitative tightening",
    "quantitative easing",
    "Fed pivot",

    # 2) US Politics
    "US politics",
    "Donald Trump",
    "Joe Biden",
    "White House",
    "Congress",
    "U.S. Congress",
    "Senate",
    "House of Representatives",
    "trade war",
    "US-China trade tensions",
    "tariffs",
    "sanctions",
    "national security",
    "executive order",

    # 3) Semiconductors (chips)
    "semiconductors (chips)",
    "semiconductor",
    "semiconductors",
    "chip",
    "chips",
    "CPU",
    "GPU",
    "APU",
    "SoC",
    "chipset",
    "fab",
    "foundry",
    "fabless",
    "wafer",
    "manufacturing node (5 nm, 3 nm)",
    "semiconductor supply chain",
    "chip shortage",
    "semiconductor shortage",
    "chip war",
    "export controls",
    "export restrictions",
    "technology ban",
    "IP theft",
    "CHIPS Act",
    "EU Chips Act",
    "chiplets",

    # 4) Taiwan, TSMC
    "Taiwan",
    "TSMC (Taiwan Semiconductor Manufacturing Company)",
    "UMC (United Microelectronics Corporation)",
    "Foxconn",
    "Hon Hai Precision",
    "ASE Group",
    "Taiwanese semiconductor",
    "Taiwan Strait",
    "cross-strait tensions",
    "China–Taiwan tensions",
    "Taiwan crisis",
    "TAIEX",

    # 5) US–China
    "US–China relations",
    "decoupling",
    "export ban",
    "BIS restrictions",
    "commerce department",
    "U.S. Commerce Department",
    "Chinese semiconductor",
    "SMIC",
    "Huawei HiSilicon",
]

############################
# Basic fetch function
############################
def fetch_polygon_news(api_key, ticker, keyword, start_date, end_date, limit=50):
    """
    Single call to Polygon for [start_date..end_date],
    combining ticker=SPY & search=keyword.
    """
    s_str = start_date.strftime("%Y-%m-%d")
    e_str = end_date.strftime("%Y-%m-%d")

    url = (
        "https://api.polygon.io/v2/reference/news?"
        f"published_utc.gte={s_str}&"
        f"published_utc.lte={e_str}&"
        f"ticker={ticker}&"
        "sort=published_utc&"
        "order=asc&"
        f"limit={limit}&"
        f"search={keyword}&"   # Undocumented free-text search
        f"apiKey={api_key}"
    )

    print(f"Fetching ticker='{ticker}', keyword='{keyword}' from {s_str} to {e_str}...")
    print(url)
    r = requests.get(url)
    if r.status_code == 200:
        data = r.json()
        results = data.get("results", [])
        print(f" -> {len(results)} items returned.")
        return results
    else:
        print(f"Error {r.status_code}: {r.text}")
        return []

############################
# If half returns 50 => day-by-day
############################
def day_by_day_subrange(api_key, ticker, keyword, start_date, end_date, limit=50):
    """
    Calls fetch_polygon_news day by day over [start_date..end_date].
    We can't subdivide a single day further if it hits 50.
    """
    articles = []
    cur = start_date
    while cur <= end_date:
        day_items = fetch_polygon_news(api_key, ticker, keyword, cur, cur, limit)
        articles.extend(day_items)
        time.sleep(SLEEP_SECONDS)
        cur += timedelta(days=1)
    return articles

############################
# "Half-Week" approach
############################
def get_news_for_halfweek(api_key, ticker, keyword, subrange_start, subrange_end, limit=50):
    """
    Fetch one half (3-4 days). If <50 => done
    If =50 => do day-by-day on that half.
    """
    items = fetch_polygon_news(api_key, ticker, keyword, subrange_start, subrange_end, limit)
    time.sleep(SLEEP_SECONDS)
    if len(items) == 50:
        print(" -> 50 items => day-by-day for this half.")
        # day-by-day for just this subrange
        return day_by_day_subrange(api_key, ticker, keyword, subrange_start, subrange_end, limit)
    return items

############################
# Combine halves for each 7-day "week"
############################
def get_news_for_week_in_halves(api_key, ticker, keyword, w_start, w_end, limit=50):
    """
    Splits the 7-day block into 2 half-weeks (3 days + 4 days, or similarly).
    For each half, if we get 50 => do day-by-day for that half only.
    Combine results from the two halves.
    """
    days_diff = (w_end - w_start).days + 1
    if days_diff <= 3:
        # If the "week" is actually only 3 days or fewer (maybe final partial week),
        # treat it as a single chunk
        return get_news_for_halfweek(api_key, ticker, keyword, w_start, w_end, limit)

    # We'll define "mid" so the first half is about 3 or 4 days
    half = days_diff // 2  # integer division
    # subrange 1: [w_start .. mid_days]
    mid_date = w_start + timedelta(days=half - 1)
    if mid_date >= w_end:
        mid_date = w_end  # if it overflows

    # subrange #1
    sub1_end = mid_date
    sub1_items = get_news_for_halfweek(api_key, ticker, keyword, w_start, sub1_end, limit)

    # subrange #2
    sub2_start = sub1_end + timedelta(days=1)
    if sub2_start > w_end:
        return sub1_items  # no second subrange if the first used up all days
    sub2_items = get_news_for_halfweek(api_key, ticker, keyword, sub2_start, w_end, limit)

    # combine
    return sub1_items + sub2_items

############################
# Generate weekly intervals for 2024
############################
def generate_weeks_2024():
    weeks = []
    start_2024 = datetime(2024, 1, 1)
    end_2024   = datetime(2024, 12, 31)

    cur = start_2024
    while cur <= end_2024:
        w_end = cur + timedelta(days=6)
        if w_end > end_2024:
            w_end = end_2024
        weeks.append((cur, w_end))
        cur = w_end + timedelta(days=1)
    return weeks

weeks_2024 = generate_weeks_2024()

############################
# MAIN LOOP
############################
for kw in keywords:
    print(f"\n=== KEYWORD: {kw} ===")
    all_articles = []

    for (w_start, w_end) in weeks_2024:
        # fetch half-week approach for each 7-day block
        week_items = get_news_for_week_in_halves(API_KEY, TICKER, kw, w_start, w_end, LIMIT)

        # label them with "keyword", "week_start", "week_end"
        for it in week_items:
            it["keyword"]    = kw
            it["week_start"] = w_start.strftime("%Y-%m-%d")
            it["week_end"]   = w_end.strftime("%Y-%m-%d")

        all_articles.extend(week_items)

    # after finishing all weeks for this keyword, write a CSV
    if all_articles:
        df = pd.DataFrame(all_articles)
        safe_kw = kw.replace(" ", "_").replace("/", "_")
        csv_filename = f"polygon_halfweek_{TICKER}_{safe_kw}.csv"
        df.to_csv(csv_filename, index=False)

        files.download(csv_filename)
        print(f"Saved CSV '{csv_filename}' with {len(df)} records.")
    else:
        print(f"No articles found for keyword='{kw}' with ticker='{TICKER}' in 2024.")
