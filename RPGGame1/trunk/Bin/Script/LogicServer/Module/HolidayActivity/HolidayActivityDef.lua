--节日活动相关定义
gtHolidayActType = 
{
    eAnswers = 1,
    eExperience = 2,
    eTeachTest = 3,
}

gtHolidayActClass = 
{
    [gtHolidayActType.eAnswers] = CHolidayActAnswers,
    [gtHolidayActType.eExperience] = CHolidayActExperience,
    [gtHolidayActType.eTeachTest] = CHolidayActTeachTest,
}