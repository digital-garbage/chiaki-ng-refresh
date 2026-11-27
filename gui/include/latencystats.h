// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL

#ifndef CHIAKI_LATENCYSTATS_H
#define CHIAKI_LATENCYSTATS_H

#include <atomic>
#include <cstdint>

// Per-second latency figures, written by the video path and printed to the session log
// by StreamSession as "[lat] ..." lines.
namespace LatencyStats
{
	struct Stat
	{
		std::atomic<uint64_t> sum_us{0}, max_us{0}, count{0};
		void add(uint64_t us)
		{
			sum_us += us;
			count++;
			uint64_t max = max_us.load();
			while(us > max && !max_us.compare_exchange_weak(max, us)) {}
		}
		// returns average and maximum in ms and starts over
		void take(double &avg_ms, double &max_ms, uint64_t &n)
		{
			n = count.exchange(0);
			const uint64_t sum = sum_us.exchange(0);
			avg_ms = n ? sum / 1000.0 / n : 0;
			max_ms = max_us.exchange(0) / 1000.0;
		}
	};

	inline std::atomic<uint64_t> sample_in_us{0}; // when the newest complete video frame arrived from the network
	inline Stat decode;  // network frame in -> decoder done
	inline Stat display; // network frame in -> handed to the screen
	inline Stat pad_poll;   // time between two controller polls
	inline Stat pad_call;   // time spent inside one controller poll
	inline Stat pad_report; // time between two stick reports while the stick moves
}

#endif
