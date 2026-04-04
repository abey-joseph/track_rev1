import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:track/core/constants/animation_constants.dart';
import 'package:track/core/error/failures.dart';
import 'package:track/core/extensions/context_extensions.dart';
import 'package:track/core/router/app_router.gr.dart';
import 'package:track/features/habits/domain/entities/habit_with_details.dart';
import 'package:track/features/habits/presentation/bloc/habits_bloc.dart';
import 'package:track/features/habits/presentation/bloc/habits_event.dart';
import 'package:track/features/habits/presentation/bloc/habits_state.dart';
import 'package:track/features/habits/presentation/widgets/habit_card.dart';

@RoutePage()
class HabitsPage extends StatelessWidget {
  const HabitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // HabitsBloc is provided by AppShellPage — no local BlocProvider needed.
    return const _HabitsView();
  }
}

class _HabitsView extends StatelessWidget {
  const _HabitsView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textTheme = context.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocBuilder<HabitsBloc, HabitsState>(
        buildWhen: (prev, curr) {
          // Only rebuild when the state type changes or the habits list differs
          if (prev.runtimeType != curr.runtimeType) return true;
          if (prev is HabitsLoaded && curr is HabitsLoaded) {
            return prev.habits != curr.habits;
          }
          return true;
        },
        builder:
            (context, state) => switch (state) {
              HabitsInitial() || HabitsLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
              HabitsLoaded(:final habits) =>
                habits.isEmpty
                    ? _buildEmptyState(colorScheme, textTheme)
                    : _buildHabitsList(context, habits),
              HabitsError(:final failure) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: colorScheme.error.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      switch (failure) {
                        ServerFailure(:final message) => message,
                        CacheFailure(:final message) => message,
                        NetworkFailure(:final message) => message,
                        AuthFailure(:final message) => message,
                        UnexpectedFailure(:final message) => message,
                      },
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed:
                          () => context.read<HabitsBloc>().add(
                            const HabitsEvent.refreshRequested(),
                          ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Your habits will appear here',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track daily habits and build streaks',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsList(BuildContext context, List<HabitWithDetails> habits) {
    final colorScheme = context.colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: habits.length + 1, // +1 for bottom spacer with quote
      itemBuilder: (context, index) {
        if (index < habits.length) {
          return _AnimatedHabitCard(
            key: ValueKey(habits[index].habit.id),
            habitWithDetails: habits[index],
            index: index,
            onTap:
                () => context.router.push(
                  HabitDetailRoute(habitId: habits[index].habit.id.toString()),
                ),
          );
        }
        // Bottom spacer with quote — keeps last card above the FAB
        final quote = (_habitQuotes.toList()..shuffle()).first;
        return Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 100),
          child: Column(
            children: [
              Icon(
                Icons.format_quote_rounded,
                size: 28,
                color: colorScheme.onSurface.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 8),
              Text(
                quote.$1,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.25),
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '— ${quote.$2}',
                textAlign: TextAlign.center,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedHabitCard extends StatefulWidget {
  const _AnimatedHabitCard({
    required this.habitWithDetails,
    required this.index,
    required this.onTap,
    super.key,
  });

  final HabitWithDetails habitWithDetails;
  final int index;
  final VoidCallback onTap;

  @override
  State<_AnimatedHabitCard> createState() => _AnimatedHabitCardState();
}

class _AnimatedHabitCardState extends State<_AnimatedHabitCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AnimationConstants.defaultDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: AnimationConstants.enterCurve,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AnimationConstants.enterCurve,
      ),
    );

    Future.delayed(
      Duration(
        milliseconds:
            AnimationConstants.staggerDelay.inMilliseconds * widget.index,
      ),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: HabitCard(
            habitWithDetails: widget.habitWithDetails,
            onTap: widget.onTap,
            onDelete: () {
              context.read<HabitsBloc>().add(
                    HabitsEvent.deleteHabit(
                      habitId: widget.habitWithDetails.habit.id,
                    ),
                  );
            },
          ),
        ),
      ),
    );
  }
}

const _habitQuotes = <(String, String)>[
  (
    'We are what we repeatedly do.\nExcellence, then, is not an act, but a habit.',
    'Aristotle',
  ),
  (
    'Small disciplines repeated with consistency\nlead to great achievements gained slowly over time.',
    'John C. Maxwell',
  ),
  (
    'Motivation is what gets you started.\nHabit is what keeps you going.',
    'Jim Ryun',
  ),
  (
    'The secret of your future\nis hidden in your daily routine.',
    'Mike Murdock',
  ),
  (
    'Success is the sum of small efforts,\nrepeated day in and day out.',
    'Robert Collier',
  ),
  ('Habits are the compound interest\nof self-improvement.', 'James Clear'),
  (
    'You do not rise to the level of your goals.\nYou fall to the level of your systems.',
    'James Clear',
  ),
  (
    'Every action you take is a vote\nfor the type of person you wish to become.',
    'James Clear',
  ),
  (
    'The chains of habit are too light to be felt\nuntil they are too heavy to be broken.',
    'Warren Buffett',
  ),
  ('First we make our habits,\nthen our habits make us.', 'Charles C. Noble'),
  (
    'A habit cannot be tossed out the window;\nit must be coaxed down the stairs a step at a time.',
    'Mark Twain',
  ),
  (
    'Depending on what they are,\nour habits will either make us or break us.',
    'Sean Covey',
  ),
  (
    'The only way to break a bad habit\nis to replace it with a better one.',
    'Unknown',
  ),
  (
    'Your net worth to the world is usually determined\nby what remains after your bad habits\nare subtracted from your good ones.',
    'Benjamin Franklin',
  ),
  ('Good habits formed at youth\nmake all the difference.', 'Aristotle'),
  (
    'Habit is a cable; we weave a thread each day,\nand at last we cannot break it.',
    'Horace Mann',
  ),
  ('The successful person is the average person, focused.', 'Unknown'),
  (
    'It is easier to prevent bad habits\nthan to break them.',
    'Benjamin Franklin',
  ),
  ('Quality is not an act, it is a habit.', 'Aristotle'),
  (
    'Watch your thoughts, they become your words;\nwatch your words, they become your actions;\nwatch your actions, they become your habits.',
    'Lao Tzu',
  ),
  (
    'Sow a thought, reap an action;\nsow an action, reap a habit;\nsow a habit, reap a character.',
    'Stephen Covey',
  ),
  ('Make it easy to do right\nand hard to do wrong.', 'Unknown'),
  ('The hard days are what make you stronger.', 'Aly Raisman'),
  (
    'Discipline is choosing between\nwhat you want now\nand what you want most.',
    'Abraham Lincoln',
  ),
  ('Don\u2019t count the days,\nmake the days count.', 'Muhammad Ali'),
  (
    'The difference between who you are\nand who you want to be\nis what you do.',
    'Unknown',
  ),
  ('Start where you are.\nUse what you have.\nDo what you can.', 'Arthur Ashe'),
  ('A journey of a thousand miles\nbegins with a single step.', 'Lao Tzu'),
  ('Consistency is the true foundation\nof trust.', 'Roy T. Bennett'),
  (
    'You will never change your life\nuntil you change something you do daily.',
    'John C. Maxwell',
  ),
  (
    'People do not decide their futures.\nThey decide their habits,\nand their habits decide their futures.',
    'F. M. Alexander',
  ),
  (
    'Repetition is the mother of learning,\nthe father of action,\nwhich makes it the architect of accomplishment.',
    'Zig Ziglar',
  ),
  (
    'Champions don\u2019t do extraordinary things.\nThey do ordinary things,\nbut they do them without thinking.',
    'Charles Duhigg',
  ),
  ('Long-term consistency\ntrumps short-term intensity.', 'Bruce Lee'),
  (
    'We become what we want to be\nby consistently being what we want to become.',
    'Richard G. Scott',
  ),
  ('The only way to do great work\nis to love what you do.', 'Steve Jobs'),
  (
    'Perseverance is not a long race;\nit is many short races one after the other.',
    'Walter Elliot',
  ),
  (
    'It\u2019s not what we do once in a while\nthat shapes our lives,\nbut what we do consistently.',
    'Tony Robbins',
  ),
  ('Be patient with yourself.\nSelf-growth is tender.', 'Unknown'),
  ('Progress, not perfection.', 'Unknown'),
  ('Little by little, one travels far.', 'J. R. R. Tolkien'),
  (
    'The man who moves a mountain\nbegins by carrying away small stones.',
    'Confucius',
  ),
  (
    'Dripping water hollows out stone\nnot through force but through persistence.',
    'Ovid',
  ),
  (
    'What you do every day matters more\nthan what you do once in a while.',
    'Gretchen Rubin',
  ),
  ('Showing up is 80 percent of life.', 'Woody Allen'),
  ('One percent better every day.', 'James Clear'),
  (
    'Do something today\nthat your future self will thank you for.',
    'Sean Patrick Flanery',
  ),
  ('You don\u2019t have to be extreme,\njust consistent.', 'Unknown'),
  (
    'The best time to plant a tree was 20 years ago.\nThe second best time is now.',
    'Chinese Proverb',
  ),
  ('How you do anything\nis how you do everything.', 'T. Harv Eker'),
  ('Fall seven times, stand up eight.', 'Japanese Proverb'),
  ('Hard choices, easy life.\nEasy choices, hard life.', 'Jerzy Gregorek'),
  (
    'Inch by inch, life\u2019s a cinch.\nYard by yard, life is hard.',
    'John Bytheway',
  ),
  (
    'Success isn\u2019t always about greatness.\nIt\u2019s about consistency.',
    'Dwayne Johnson',
  ),
  (
    'Rome wasn\u2019t built in a day,\nbut they were laying bricks every hour.',
    'John Heywood',
  ),
  ('If you are going through hell,\nkeep going.', 'Winston Churchill'),
  ('Action is the foundational key\nto all success.', 'Pablo Picasso'),
  (
    'An ounce of practice\nis worth more than tons of preaching.',
    'Mahatma Gandhi',
  ),
  ('Be the change\nthat you wish to see in the world.', 'Mahatma Gandhi'),
  ('The only impossible journey\nis the one you never begin.', 'Tony Robbins'),
  (
    'What we fear doing most is usually\nwhat we most need to do.',
    'Tim Ferriss',
  ),
  ('Your habits are a reflection\nof your identity.', 'James Clear'),
  (
    'The cost of a good habit\nis in the present.\nThe cost of a bad habit\nis in the future.',
    'James Clear',
  ),
  (
    'Habits are not a finish line to be crossed.\nThey are a lifestyle to be lived.',
    'James Clear',
  ),
  ('Dream big. Start small.\nBut most of all, start.', 'Simon Sinek'),
  (
    'The greatest glory in living\nlies not in never falling,\nbut in rising every time we fall.',
    'Nelson Mandela',
  ),
  ('Well done is better than well said.', 'Benjamin Franklin'),
  ('It always seems impossible\nuntil it\u2019s done.', 'Nelson Mandela'),
  ('Believe you can\nand you\u2019re halfway there.', 'Theodore Roosevelt'),
  ('With self-discipline,\nmost anything is possible.', 'Theodore Roosevelt'),
  (
    'The pain of discipline\nis far less than the pain of regret.',
    'Sarah Bombell',
  ),
  ('Discipline is the bridge\nbetween goals and accomplishment.', 'Jim Rohn'),
  ('Good things come to those who hustle.', 'Anais Nin'),
  (
    'Continuous effort, not strength or intelligence,\nis the key to unlocking our potential.',
    'Winston Churchill',
  ),
  ('Energy and persistence\nconquer all things.', 'Benjamin Franklin'),
  (
    'Great works are performed\nnot by strength, but by perseverance.',
    'Samuel Johnson',
  ),
  (
    'What saves a man is to take a step.\nThen another step.',
    'Antoine de Saint-Exup\u00e9ry',
  ),
  (
    'You are never too old\nto set another goal\nor to dream a new dream.',
    'C. S. Lewis',
  ),
  ('The habit of persistence\nis the habit of victory.', 'Herbert Kaufman'),
  (
    'Stay committed to your decisions,\nbut stay flexible in your approach.',
    'Tony Robbins',
  ),
  ('A little progress each day\nadds up to big results.', 'Satya Nani'),
  ('Don\u2019t watch the clock;\ndo what it does. Keep going.', 'Sam Levenson'),
  (
    'The way to get started\nis to quit talking and begin doing.',
    'Walt Disney',
  ),
  ('In the middle of every difficulty\nlies opportunity.', 'Albert Einstein'),
  (
    'Character is the ability\nto carry out a good resolution\nlong after the excitement of the moment has passed.',
    'Cavett Robert',
  ),
  (
    'Success is not final, failure is not fatal:\nit is the courage to continue that counts.',
    'Winston Churchill',
  ),
  (
    'Courage is not having the strength to go on;\nit is going on when you don\u2019t have the strength.',
    'Theodore Roosevelt',
  ),
  ('Habits change into character.', 'Ovid'),
  ('Nothing will work\nunless you do.', 'Maya Angelou'),
  ('The secret to getting ahead\nis getting started.', 'Mark Twain'),
  (
    'Almost everything will work again\nif you unplug it for a few minutes\u2026\nincluding you.',
    'Anne Lamott',
  ),
  (
    'Take care of your body.\nIt\u2019s the only place you have to live.',
    'Jim Rohn',
  ),
  ('The future depends on\nwhat you do today.', 'Mahatma Gandhi'),
  ('Be stronger than your excuses.', 'Unknown'),
  ('Strive for progress, not perfection.', 'Unknown'),
  ('Today is a good day\nto have a good day.', 'Unknown'),
  ('Your life is a reflection\nof your habits.', 'Unknown'),
  ('Small steps every day.', 'Unknown'),
  ('Done is better than perfect.', 'Sheryl Sandberg'),
  ('Push yourself,\nbecause no one else is going to do it for you.', 'Unknown'),
  ('Slow progress is still progress.', 'Unknown'),
];
